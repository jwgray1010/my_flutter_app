/**
 * Score pipeline these rehearsal controls sit on.
 * Recorded before the staff, tempo, and repeat work. The MusicXML parser
 * and recognition path stay this revision.
 */
export const PIPELINE_VERSION = "score-recognition-harness@8acdf1146932";

/**
 * Each control can be turned off without removing the others.
 * They are enabled only after that control's own checks pass.
 */
export const featureFlags = {
  staffColorOverlay: true,
  rehearsalTempoControl: false,
  repeatNavigationV2: false,
  tiePlaybackV2: true,
  sharedStaffVoices: true,
};
