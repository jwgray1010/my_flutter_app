#!/usr/bin/env python3
"""Keep a mis-segmented page when Audiveris rhythm cleanup sees a null measure.

Audiveris 5.11.0 Voices.refineSystem does:

    Measure measure = stack.getMeasureAt(part);
    measure.purgeVoices();

On a photocopy, system segmentation can invent a system with no start
barline. getMeasureAt then returns null and purgeVoices throws. That
NullPointerException aborts the whole sheet, so export drops the page
even when the rest of the systems were read.

This rewrites that straight-line cleanup into one call:

    List voices = Voices.purgeVoicesIfPresent(measure);

which returns an empty list when the measure is missing. The following
voice loop then has nothing to walk, and the page continues. A measure
that does exist still runs purgeVoices, sortVoices, renameVoices, and
getVoices in that order.

The replacement is the same length as the original instructions, so
existing branch offsets and stack-map frames stay valid. The new method
is appended with its own stack map.

Idempotent. Exits 0 when the jar is already patched, 2 when this
Audiveris build does not contain the expected instruction sequence.
"""

from __future__ import annotations

import argparse
import shutil
import sys
import zipfile
from pathlib import Path

CLASS_NAME = "org/audiveris/omr/sheet/rhythm/Voices.class"
MEASURE = "org/audiveris/omr/sheet/rhythm/Measure"
VOICES = "org/audiveris/omr/sheet/rhythm/Voices"
HELPER_NAME = "purgeVoicesIfPresent"
HELPER_DESC = "(Lorg/audiveris/omr/sheet/rhythm/Measure;)Ljava/util/List;"
LIST_DESC = "()Ljava/util/List;"

# aload_0, ifnull +20, then the four Measure calls, areturn,
# invokestatic Collections.emptyList, areturn.
HELPER_CODE_LEN = 25


class PatchError(Exception):
    pass


def _u2(data: bytes | bytearray, off: int) -> int:
    return int.from_bytes(data[off : off + 2], "big")


def _u4(data: bytes | bytearray, off: int) -> int:
    return int.from_bytes(data[off : off + 4], "big")


def parse_constant_pool(data: bytes | bytearray) -> tuple[list, int]:
    if data[:4] != b"\xca\xfe\xba\xbe":
        raise PatchError("not a Java class file")
    count = _u2(data, 8)
    entries: list[tuple[int, bytes] | None] = [None] * count
    off = 10
    index = 1
    while index < count:
        tag = data[off]
        start = off
        off += 1
        if tag == 1:
            length = _u2(data, off)
            off += 2 + length
            slots = 1
        elif tag in (7, 8, 16, 19, 20):
            off += 2
            slots = 1
        elif tag in (3, 4, 9, 10, 11, 12, 17, 18):
            off += 4
            slots = 1
        elif tag in (5, 6):
            off += 8
            slots = 2
        elif tag == 15:
            off += 3
            slots = 1
        else:
            raise PatchError(f"unknown constant-pool tag {tag} at offset {start}")
        entries[index] = (tag, bytes(data[start:off]))
        # Long and Double occupy two constant-pool slots. The second slot
        # stays None because `entries` was sized to constant_pool_count.
        index += slots
    if len(entries) != count:
        raise PatchError(
            f"constant pool size mismatch: parsed {len(entries)} expected {count}"
        )
    return entries, off


def utf8(entries: list, index: int) -> str:
    tag, raw = entries[index]
    if tag != 1:
        raise PatchError(f"constant pool #{index} is tag {tag}, not Utf8")
    length = int.from_bytes(raw[1:3], "big")
    return raw[3 : 3 + length].decode("utf-8")


def class_name(entries: list, index: int) -> str:
    tag, raw = entries[index]
    if tag != 7:
        raise PatchError(f"constant pool #{index} is tag {tag}, not Class")
    return utf8(entries, int.from_bytes(raw[1:3], "big"))


def methodref(entries: list, index: int) -> tuple[str, str, str]:
    tag, raw = entries[index]
    if tag != 10:
        raise PatchError(f"constant pool #{index} is tag {tag}, not Methodref")
    cls = int.from_bytes(raw[1:3], "big")
    nat = int.from_bytes(raw[3:5], "big")
    nat_tag, nat_raw = entries[nat]
    if nat_tag != 12:
        raise PatchError(f"constant pool #{nat} is not NameAndType")
    name = utf8(entries, int.from_bytes(nat_raw[1:3], "big"))
    desc = utf8(entries, int.from_bytes(nat_raw[3:5], "big"))
    return class_name(entries, cls), name, desc


def find_methodref(entries: list, owner: str, name: str, desc: str) -> int:
    found = [
        index
        for index, entry in enumerate(entries)
        if entry and entry[0] == 10 and methodref(entries, index) == (owner, name, desc)
    ]
    if len(found) != 1:
        raise PatchError(
            f"expected one Methodref {owner}.{name}{desc}, found {len(found)}"
        )
    return found[0]


def skip_attributes(data: bytes | bytearray, off: int) -> int:
    count = _u2(data, off)
    off += 2
    for _ in range(count):
        off += 2
        length = _u4(data, off)
        off += 4 + length
    return off


def iter_members(data: bytes | bytearray, off: int) -> tuple[int, list[dict]]:
    count = _u2(data, off)
    off += 2
    members = []
    for _ in range(count):
        start = off
        name = _u2(data, off + 2)
        desc = _u2(data, off + 4)
        attr_count_off = off + 6
        end = skip_attributes(data, attr_count_off)
        members.append(
            {
                "start": start,
                "end": end,
                "name_index": name,
                "desc_index": desc,
            }
        )
        off = end
    return off, members


def code_attribute(data: bytes | bytearray, entries: list, member: dict) -> dict:
    off = member["start"] + 6
    count = _u2(data, off)
    off += 2
    code_name = None
    for index, entry in enumerate(entries):
        if entry and entry[0] == 1 and utf8(entries, index) == "Code":
            code_name = index
            break
    if code_name is None:
        raise PatchError("class has no Code attribute name")
    for _ in range(count):
        name_index = _u2(data, off)
        length = _u4(data, off + 2)
        info = off + 6
        if name_index == code_name:
            code_len = _u4(data, info + 4)
            return {
                "info": info,
                "code_off": info + 8,
                "code_len": code_len,
                "max_stack": _u2(data, info),
                "max_locals": _u2(data, info + 2),
            }
        off = info + length
    raise PatchError("method has no Code attribute")


def add_utf8(entries: list, text: str) -> int:
    encoded = text.encode("utf-8")
    for index, entry in enumerate(entries):
        if entry and entry[0] == 1 and utf8(entries, index) == text:
            return index
    raw = b"\x01" + len(encoded).to_bytes(2, "big") + encoded
    entries.append((1, raw))
    return len(entries) - 1


def add_class(entries: list, name: str) -> int:
    for index, entry in enumerate(entries):
        if entry and entry[0] == 7 and class_name(entries, index) == name:
            return index
    name_index = add_utf8(entries, name)
    entries.append((7, b"\x07" + name_index.to_bytes(2, "big")))
    return len(entries) - 1


def add_name_and_type(entries: list, name: str, desc: str) -> int:
    for index, entry in enumerate(entries):
        if not entry or entry[0] != 12:
            continue
        raw = entry[1]
        if utf8(entries, int.from_bytes(raw[1:3], "big")) == name and utf8(
            entries, int.from_bytes(raw[3:5], "big")
        ) == desc:
            return index
    name_index = add_utf8(entries, name)
    desc_index = add_utf8(entries, desc)
    entries.append(
        (
            12,
            b"\x0c" + name_index.to_bytes(2, "big") + desc_index.to_bytes(2, "big"),
        )
    )
    return len(entries) - 1


def add_methodref(entries: list, owner: str, name: str, desc: str) -> int:
    for index, entry in enumerate(entries):
        if entry and entry[0] == 10 and methodref(entries, index) == (owner, name, desc):
            return index
    cls = add_class(entries, owner)
    nat = add_name_and_type(entries, name, desc)
    entries.append((10, b"\x0a" + cls.to_bytes(2, "big") + nat.to_bytes(2, "big")))
    return len(entries) - 1


def helper_already_present(entries: list) -> bool:
    for index, entry in enumerate(entries):
        if not entry or entry[0] != 10:
            continue
        owner, name, desc = methodref(entries, index)
        if owner == VOICES and name == HELPER_NAME and desc == HELPER_DESC:
            return True
    return False


def build_helper_method(
    entries: list, purge: int, sort: int, rename: int, get_voices: int
) -> tuple[bytes, int]:
    helper_ref = add_methodref(entries, VOICES, HELPER_NAME, HELPER_DESC)
    _owner, helper_name_text, helper_desc_text = methodref(entries, helper_ref)
    if helper_name_text != HELPER_NAME or helper_desc_text != HELPER_DESC:
        raise PatchError("helper Methodref was not recorded")
    # Reuse the name and descriptor constants the Methodref already points at.
    _tag, helper_raw = entries[helper_ref]
    helper_nat = int.from_bytes(helper_raw[3:5], "big")
    _nat_tag, nat_raw = entries[helper_nat]
    helper_name = int.from_bytes(nat_raw[1:3], "big")
    helper_desc = int.from_bytes(nat_raw[3:5], "big")
    empty = add_methodref(entries, "java/util/Collections", "emptyList", LIST_DESC)
    code_name = add_utf8(entries, "Code")
    stack_map_name = add_utf8(entries, "StackMapTable")

    code = bytearray(
        [
            0x2A,  # aload_0
            0xC6,
            0x00,
            0x14,  # ifnull 21
            0x2A,  # aload_0
            0xB6,
            0x00,
            0x00,  # invokevirtual purgeVoices
            0x2A,
            0xB6,
            0x00,
            0x00,  # sortVoices
            0x2A,
            0xB6,
            0x00,
            0x00,  # renameVoices
            0x2A,
            0xB6,
            0x00,
            0x00,  # getVoices
            0xB0,  # areturn
            0xB8,
            0x00,
            0x00,  # invokestatic emptyList
            0xB0,  # areturn
        ]
    )
    if len(code) != HELPER_CODE_LEN:
        raise PatchError(f"helper code length {len(code)}")

    def put_invoke(at: int, index: int) -> None:
        code[at] = (index >> 8) & 0xFF
        code[at + 1] = index & 0xFF

    put_invoke(6, purge)
    put_invoke(10, sort)
    put_invoke(14, rename)
    put_invoke(18, get_voices)
    put_invoke(22, empty)

    # same_frame at bytecode offset 21. frame_type == offset_delta.
    stack_map = (
        stack_map_name.to_bytes(2, "big")
        + (3).to_bytes(4, "big")
        + (1).to_bytes(2, "big")
        + bytes([21])
    )
    code_info = (
        (1).to_bytes(2, "big")  # max_stack
        + (1).to_bytes(2, "big")  # max_locals
        + len(code).to_bytes(4, "big")
        + bytes(code)
        + (0).to_bytes(2, "big")  # exception table
        + (1).to_bytes(2, "big")  # attributes
        + stack_map
    )
    code_attr = code_name.to_bytes(2, "big") + len(code_info).to_bytes(4, "big") + code_info
    method = (
        (0x0009).to_bytes(2, "big")  # public static
        + helper_name.to_bytes(2, "big")
        + helper_desc.to_bytes(2, "big")
        + (1).to_bytes(2, "big")
        + code_attr
    )
    return method, helper_ref


def patch_class(data: bytes) -> bytes:
    entries, cp_end = parse_constant_pool(data)
    if helper_already_present(entries):
        return data

    purge = find_methodref(entries, MEASURE, "purgeVoices", "()V")
    sort = find_methodref(entries, MEASURE, "sortVoices", "()V")
    rename = find_methodref(entries, MEASURE, "renameVoices", "()V")
    get_voices = find_methodref(entries, MEASURE, "getVoices", LIST_DESC)

    off = cp_end
    off += 6  # access, this, super
    iface_count = _u2(data, off)
    off += 2 + 2 * iface_count
    off, _fields = iter_members(data, off)
    methods_count_off = off
    off, methods = iter_members(data, off)
    attributes_off = off

    refine = None
    for member in methods:
        if utf8(entries, member["name_index"]) == "refineSystem" and utf8(
            entries, member["desc_index"]
        ) == "(Lorg/audiveris/omr/sheet/SystemInfo;)V":
            refine = member
            break
    if refine is None:
        raise PatchError("Voices.refineSystem(SystemInfo) was not found")

    code = code_attribute(data, entries, refine)
    original = bytes(
        [
            0x19,
            0x08,
            0xB6,
            (purge >> 8) & 0xFF,
            purge & 0xFF,
            0x19,
            0x08,
            0xB6,
            (sort >> 8) & 0xFF,
            sort & 0xFF,
            0x19,
            0x08,
            0xB6,
            (rename >> 8) & 0xFF,
            rename & 0xFF,
            0x19,
            0x08,
            0xB6,
            (get_voices >> 8) & 0xFF,
            get_voices & 0xFF,
        ]
    )
    code_bytes = data[code["code_off"] : code["code_off"] + code["code_len"]]
    found_at = code_bytes.find(original)
    if found_at < 0:
        raise PatchError(
            "refineSystem does not contain the purge/sort/rename/getVoices sequence "
            f"(Audiveris build is not 5.11.0, or it is already patched differently). "
            f"purge=#{purge} sort=#{sort} rename=#{rename} getVoices=#{get_voices}"
        )
    if code_bytes.find(original, found_at + 1) >= 0:
        raise PatchError("purge/sort/rename/getVoices sequence appears more than once")
    site = code["code_off"] + found_at
    if data[site + len(original) : site + len(original) + 2] != b"\x3a\x09":
        raise PatchError("cleanup sequence is not followed by astore 9")

    # Append pool entries only after the sequence is confirmed, so a mismatch
    # leaves the class untouched.
    pool_before = len(entries)
    helper, helper_ref = build_helper_method(entries, purge, sort, rename, get_voices)
    new_entries = entries[pool_before:]
    if any(entry is None for entry in new_entries):
        raise PatchError("new constant-pool entries must occupy one slot each")
    pool_bytes = b"".join(entry[1] for entry in new_entries if entry is not None)

    replacement = bytes(
        [
            0x19,
            0x08,
            0xB8,
            (helper_ref >> 8) & 0xFF,
            helper_ref & 0xFF,
        ]
    ) + b"\x00" * (len(original) - 5)
    if len(replacement) != len(original):
        raise PatchError("replacement instruction length changed")

    patched = bytearray(data)
    patched[site : site + len(original)] = replacement
    patched[8:10] = (len(entries)).to_bytes(2, "big")
    patched[cp_end:cp_end] = pool_bytes
    methods_count_off += len(pool_bytes)
    attributes_off += len(pool_bytes)
    patched[methods_count_off : methods_count_off + 2] = (
        _u2(patched, methods_count_off) + 1
    ).to_bytes(2, "big")
    patched[attributes_off:attributes_off] = helper

    # Re-parse to catch a broken pool or method table before we ship it.
    check_entries, check_cp_end = parse_constant_pool(patched)
    if not helper_already_present(check_entries):
        raise PatchError("patched class is missing purgeVoicesIfPresent")
    check_off = check_cp_end + 6
    check_off += 2 + 2 * _u2(patched, check_off)
    check_off, _ = iter_members(patched, check_off)
    check_off, check_methods = iter_members(patched, check_off)
    names = [utf8(check_entries, member["name_index"]) for member in check_methods]
    if HELPER_NAME not in names or names.count("refineSystem") != 1:
        raise PatchError(f"unexpected methods after patch: {names}")
    helper_member = next(
        member for member in check_methods if utf8(check_entries, member["name_index"]) == HELPER_NAME
    )
    helper_code = code_attribute(patched, check_entries, helper_member)
    if helper_code["code_len"] != HELPER_CODE_LEN or helper_code["max_stack"] != 1:
        raise PatchError("helper Code attribute was not written intact")
    if check_off != len(patched) - _class_attributes_size(patched, check_off):
        raise PatchError("class ended before its attributes")
    return bytes(patched)


def _class_attributes_size(data: bytes | bytearray, off: int) -> int:
    start = off
    end = skip_attributes(data, off)
    if end != len(data):
        raise PatchError(
            f"trailing {len(data) - end} bytes after class attributes (from {start})"
        )
    return end - start


def patch_bytes(data: bytes) -> tuple[bytes, str]:
    entries, _ = parse_constant_pool(data)
    if helper_already_present(entries):
        return data, "already-patched"
    return patch_class(data), "patched"


def patch_jar(jar_path: Path) -> str:
    with zipfile.ZipFile(jar_path, "r") as archive:
        try:
            original = archive.read(CLASS_NAME)
        except KeyError as exc:
            raise PatchError(f"{jar_path} has no {CLASS_NAME}") from exc
        patched, status = patch_bytes(original)
        if status == "already-patched":
            return status
        infos = archive.infolist()
        payload = {info.filename: archive.read(info.filename) for info in infos}

    payload[CLASS_NAME] = patched
    tmp = jar_path.with_suffix(jar_path.suffix + ".tmp")
    with zipfile.ZipFile(jar_path, "r") as source, zipfile.ZipFile(
        tmp, "w"
    ) as target:
        for info in source.infolist():
            target.writestr(info, payload[info.filename])
    tmp.replace(jar_path)
    return "patched"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "target",
        type=Path,
        help="audiveris.jar or an extracted Voices.class",
    )
    args = parser.parse_args()
    target = args.target
    if not target.is_file():
        print(f"Audiveris patch target does not exist: {target}", file=sys.stderr)
        return 1
    try:
        if target.suffix == ".jar":
            status = patch_jar(target)
        elif target.suffix == ".class":
            patched, status = patch_bytes(target.read_bytes())
            if status == "patched":
                backup = target.with_suffix(".class.bak")
                if not backup.exists():
                    shutil.copy2(target, backup)
                target.write_bytes(patched)
        else:
            print(f"expected a .jar or .class file, got {target}", file=sys.stderr)
            return 1
    except PatchError as exc:
        print(f"Audiveris voice patch failed: {exc}", file=sys.stderr)
        return 2
    if status == "already-patched":
        print(f"{target} already skips a null measure in Voices.refineSystem")
    else:
        print(f"Patched {target}: a null measure no longer aborts rhythm cleanup")
    return 0


if __name__ == "__main__":
    sys.exit(main())
