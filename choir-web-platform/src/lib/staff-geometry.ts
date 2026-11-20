import type { StaffMarkerPosition, StaffMarkerPositionById } from "@/lib/staff-colors";

export interface StaffGeometry {
  resolved: boolean;
  reason: string | null;
  positions: StaffMarkerPositionById;
}

/**
 * Read staff positions only from explicit MusicXML page and staff layout.
 * Missing page size or staff distance stays unresolved. Nothing is invented
 * from a CSS offset.
 */
export function readStaffGeometry(xml: string, staffIds: string[]): StaffGeometry {
  if (!staffIds.length) {
    return unresolved("No staves were recognized.");
  }
  if (typeof DOMParser === "undefined") {
    return unresolved("Staff coordinates could not be read in this environment.");
  }
  const doc = new DOMParser().parseFromString(xml, "application/xml");
  if (doc.querySelector("parsererror")) {
    return unresolved("MusicXML layout could not be read.");
  }
  const page = doc.querySelector("defaults > page-layout");
  const pageHeight = numberFrom(page, "page-height");
  const pageWidth = numberFrom(page, "page-width");
  const margins = page?.querySelector("page-margins");
  const topMargin = numberFrom(margins ?? null, "top-margin");
  const leftMargin = numberFrom(margins ?? null, "left-margin");
  if (
    pageHeight == null ||
    pageWidth == null ||
    pageHeight <= 0 ||
    pageWidth <= 0 ||
    topMargin == null ||
    leftMargin == null
  ) {
    return unresolved("Page size is not in the MusicXML, so staff markers are not placed on the image.");
  }
  if (doc.querySelector('print[new-page="yes"]')) {
    return unresolved("A later page has no separate staff positions, so the overlay is not placed.");
  }

  const topSystem = firstNumber(doc, "top-system-distance");
  if (topSystem == null) {
    return unresolved("System position is not in the MusicXML, so staff markers are not placed on the image.");
  }
  const defaultGap = numberFrom(doc.querySelector("defaults > staff-layout"), "staff-distance");
  const gaps: number[] = [];
  for (let index = 1; index < staffIds.length; index += 1) {
    const numbered = staffDistance(doc, index + 1);
    const gap = numbered ?? defaultGap;
    if (gap == null || gap <= 0) {
      return unresolved("Staff distance is not in the MusicXML, so staff markers are not placed on the image.");
    }
    gaps.push(gap);
  }

  const staffSize = firstNumber(doc, "staff-size") ?? 40;
  const height = clamp01(staffSize / pageHeight);
  const x = clamp01((leftMargin * 0.35) / pageWidth);
  let cursor = topMargin + topSystem;
  const positions: StaffMarkerPositionById = {};
  staffIds.forEach((staffId, index) => {
    positions[staffId] = {
      page: 1,
      x,
      y: clamp01(cursor / pageHeight),
      height,
    };
    cursor += gaps[index] ?? 0;
  });
  return { resolved: true, reason: null, positions };
}

function unresolved(reason: string): StaffGeometry {
  return { resolved: false, reason, positions: {} };
}

function staffDistance(doc: Document, staffNumber: number) {
  const layouts = Array.from(doc.querySelectorAll("staff-layout"));
  for (const layout of layouts) {
    if (layout.getAttribute("number") === String(staffNumber)) {
      return numberFrom(layout, "staff-distance");
    }
  }
  return null;
}

function firstNumber(doc: Document, tagName: string) {
  const value = textOf(doc.querySelector(tagName));
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function numberFrom(parent: Element | null | undefined, tagName: string) {
  if (!parent) {
    return null;
  }
  const value = textOf(parent.querySelector(`:scope > ${tagName}`));
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function textOf(element: Element | null | undefined) {
  const value = element?.textContent?.trim();
  return value ? value : null;
}

function clamp01(value: number) {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.min(1, value));
}

export function markerPercents(position: StaffMarkerPosition) {
  return {
    left: `${position.x * 100}%`,
    top: `${position.y * 100}%`,
    height: `${position.height * 100}%`,
  };
}
