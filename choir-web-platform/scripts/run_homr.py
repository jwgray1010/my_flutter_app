#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageOps


def _to_image_path(input_path: Path, work_dir: Path) -> Path:
    suffix = input_path.suffix.lower()
    if suffix in [".jpg", ".jpeg", ".png", ".webp"]:
        return input_path
    if suffix == ".pdf":
        try:
            import pypdfium2 as pdfium
        except Exception as exc:
            raise RuntimeError(
                "PDF support requires pypdfium2. Install with pip install pypdfium2"
            ) from exc

        pdf = pdfium.PdfDocument(str(input_path))
        if len(pdf) == 0:
            raise RuntimeError("PDF contained zero pages.")
        bitmap = pdf[0].render(scale=2.2).to_pil()
        page_image = work_dir / "pdf-page-1.png"
        bitmap.save(page_image, format="PNG")
        return page_image
    raise RuntimeError(f"Unsupported input extension for OMR: {suffix}")


def _preprocess(image_path: Path, work_dir: Path) -> Path:
    img = Image.open(image_path).convert("L")
    img = ImageOps.autocontrast(img, cutoff=1)
    img = ImageOps.equalize(img)
    max_w = 2200
    max_h = 2800
    if img.width > max_w or img.height > max_h:
        img.thumbnail((max_w, max_h))
    output_path = work_dir / "omr-input.jpg"
    img.save(output_path, format="JPEG", quality=92)
    return output_path


def _run_homr(image_path: Path, work_dir: Path) -> Path:
    cmd = [sys.executable, "-m", "homr.main", str(image_path)]
    completed = subprocess.run(
        cmd,
        cwd=str(work_dir),
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "homr failed.\nSTDOUT:\n"
            + completed.stdout[-5000:]
            + "\nSTDERR:\n"
            + completed.stderr[-5000:]
        )

    candidates = sorted(work_dir.glob("*.musicxml")) + sorted(work_dir.glob("*.xml"))
    if not candidates:
        raise RuntimeError(
            "homr completed but no MusicXML output was found in working directory."
        )
    return candidates[0]


def main() -> None:
    if len(sys.argv) < 2:
        raise RuntimeError("Missing input file path.")
    input_path = Path(sys.argv[1]).expanduser().resolve()
    if not input_path.exists():
        raise RuntimeError(f"Input file not found: {input_path}")

    base_temp_dir = Path(tempfile.mkdtemp(prefix="choir-homr-"))
    try:
        source_copy = base_temp_dir / input_path.name
        shutil.copy2(input_path, source_copy)
        image_path = _to_image_path(source_copy, base_temp_dir)
        preprocessed = _preprocess(image_path, base_temp_dir)
        musicxml_path = _run_homr(preprocessed, base_temp_dir)
        persistent_out = Path(
            tempfile.NamedTemporaryFile(prefix="choir-omr-", suffix=".musicxml", delete=False).name
        )
        persistent_out.write_text(musicxml_path.read_text(encoding="utf-8"), encoding="utf-8")
        print(json.dumps({"musicXmlPath": str(persistent_out)}))
    finally:
        shutil.rmtree(base_temp_dir, ignore_errors=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(json.dumps({"message": str(error)}))
        sys.exit(1)

