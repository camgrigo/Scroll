/**
 * AssembleSchedule  —  Office Script for "Ride Scheduler.xlsx"
 *
 * WHAT IT DOES
 *   Reads the Riders + Requests tabs, then fills in:
 *     • Schedule  — every trip for the week, grouped by Day > Zone > Time,
 *                   split into Pickup and Dropoff runs, with a heads-up flag.
 *     • Notify    — only the riders whose time differs from their usual time,
 *                   as a ready-to-use call list.
 *
 * HOW TO INSTALL (once)
 *   1. Open "Ride Scheduler.xlsx" in Excel.
 *   2. Automate tab  >  New Script.
 *   3. Delete the sample code, paste ALL of this file, click Save.
 *   4. Rename it "Assemble Schedule".
 *   5. (Optional) Automate tab > ... > Add to ribbon, so it's one click.
 *
 * EVERY WEEK
 *   Fill the Requests tab, then run this script.
 *
 * PRIVACY: runs entirely inside Excel. No data leaves the workbook.
 */

// A time is "unusual" (needs a heads-up call) if it differs from the
// rider's usual time by MORE than this many minutes. Change to taste.
const FLAG_MINUTES = 15;

const DAY_ORDER: { [d: string]: number } = { Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4 };
const ZONE_ORDER: { [z: string]: number } = { N: 0, E: 1, S: 2, W: 3 };

interface Rider {
  phone: string;
  address: string;
  zone: string;
  usualPickup: number | null;   // minutes since midnight
  usualDropoff: number | null;
}

interface Trip {
  day: string;
  zone: string;
  minutes: number;      // for sorting
  timeText: string;     // original text to display
  trip: "Pickup" | "Dropoff";
  rider: string;
  phone: string;
  address: string;
  flagged: boolean;
  usualText: string;
  diffText: string;
  note: string;
}

function main(workbook: ExcelScript.Workbook) {
  const ridersSheet = workbook.getWorksheet("Riders");
  const reqSheet = workbook.getWorksheet("Requests");
  const schedSheet = workbook.getWorksheet("Schedule");
  const notifySheet = workbook.getWorksheet("Notify");

  // ---- load Riders into a lookup ----------------------------------------
  const riders: { [name: string]: Rider } = {};
  const rRange = ridersSheet.getUsedRange();
  if (rRange) {
    const rv = rRange.getValues();
    for (let i = 2; i < rv.length; i++) { // row 1 title, row 2 header
      const name = String(rv[i][0] ?? "").trim();
      if (!name) continue;
      riders[name] = {
        phone: String(rv[i][1] ?? ""),
        address: String(rv[i][2] ?? ""),
        zone: String(rv[i][3] ?? "").trim().toUpperCase(),
        usualPickup: parseTime(rv[i][4]),
        usualDropoff: parseTime(rv[i][5]),
      };
    }
  }

  // ---- read Requests, build Trips ---------------------------------------
  const trips: Trip[] = [];
  const reqRange = reqSheet.getUsedRange();
  if (reqRange) {
    const qv = reqRange.getValues();
    for (let i = 2; i < qv.length; i++) {
      const name = String(qv[i][0] ?? "").trim();
      const day = String(qv[i][1] ?? "").trim();
      if (!name || !day) continue;
      const r = riders[name];
      const zone = r ? r.zone : "?";
      const phone = r ? r.phone : "";
      const address = r ? r.address : "";
      const note = String(qv[i][4] ?? "");

      addTrip(trips, "Pickup", qv[i][2], r ? r.usualPickup : null,
        { name, day, zone, phone, address, note });
      addTrip(trips, "Dropoff", qv[i][3], r ? r.usualDropoff : null,
        { name, day, zone, phone, address, note });
    }
  }

  // ---- sort: Day, then Zone, then Time, then Trip -----------------------
  trips.sort((a, b) =>
    (DAY_ORDER[a.day] ?? 9) - (DAY_ORDER[b.day] ?? 9) ||
    (ZONE_ORDER[a.zone] ?? 9) - (ZONE_ORDER[b.zone] ?? 9) ||
    a.minutes - b.minutes ||
    a.trip.localeCompare(b.trip));

  writeSchedule(schedSheet, trips);
  writeNotify(notifySheet, trips);
}

function addTrip(
  trips: Trip[],
  kind: "Pickup" | "Dropoff",
  rawTime: ExcelScript.CellValue,
  usual: number | null,
  base: { name: string; day: string; zone: string; phone: string; address: string; note: string }
) {
  const mins = parseTime(rawTime);
  if (mins === null) return; // no time = no trip in that direction
  let flagged = false;
  let diffText = "";
  if (usual !== null) {
    const diff = mins - usual;
    if (Math.abs(diff) > FLAG_MINUTES) {
      flagged = true;
      diffText = (diff > 0 ? "+" : "") + diff + " min";
    }
  }
  trips.push({
    day: base.day, zone: base.zone, minutes: mins, timeText: formatTime(mins),
    trip: kind, rider: base.name, phone: base.phone, address: base.address,
    flagged, usualText: usual === null ? "" : formatTime(usual),
    diffText, note: base.note,
  });
}

function writeSchedule(sheet: ExcelScript.Worksheet, trips: Trip[]) {
  clearBelowHeader(sheet, 9);
  if (trips.length === 0) return;
  const rows: (string)[][] = trips.map(t => [
    t.day, t.zone, t.timeText, t.trip, t.rider, t.phone, t.address,
    t.flagged ? "⚠ CALL" : "", t.note,
  ]);
  const range = sheet.getRangeByIndexes(2, 0, rows.length, 9);
  range.setValues(rows);
  // shade the heads-up cells orange
  for (let i = 0; i < trips.length; i++) {
    if (trips[i].flagged) {
      sheet.getRangeByIndexes(2 + i, 7, 1, 1).getFormat().getFill()
        .setColor("FCE4D6");
    }
  }
}

function writeNotify(sheet: ExcelScript.Worksheet, trips: Trip[]) {
  clearBelowHeader(sheet, 8);
  const flagged = trips.filter(t => t.flagged);
  if (flagged.length === 0) return;
  const rows = flagged.map(t => [
    t.rider, t.phone, t.day, t.trip, t.usualText, t.timeText, t.diffText, "",
  ]);
  sheet.getRangeByIndexes(2, 0, rows.length, 8).setValues(rows);
}

function clearBelowHeader(sheet: ExcelScript.Worksheet, cols: number) {
  const used = sheet.getUsedRange();
  if (!used) return;
  const last = used.getRowCount();
  if (last > 2) {
    sheet.getRangeByIndexes(2, 0, last - 2, cols).clear(ExcelScript.ClearApplyTo.contents);
    sheet.getRangeByIndexes(2, 0, last - 2, cols).getFormat().getFill().clear();
  }
}

/** Parse "10:30 AM", "9:15", "1:00 PM", "13:00", or an Excel time number. */
function parseTime(v: ExcelScript.CellValue): number | null {
  if (v === null || v === undefined || v === "") return null;
  // Excel stores times as a fraction of a day (e.g. 0.5 = noon).
  if (typeof v === "number") {
    if (v > 0 && v < 1) return Math.round(v * 24 * 60);
    return null;
  }
  const s = String(v).trim().toUpperCase();
  const m = s.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)?$/);
  if (!m) return null;
  let h = parseInt(m[1], 10);
  const min = parseInt(m[2], 10);
  const ap = m[3];
  if (ap === "PM" && h < 12) h += 12;
  if (ap === "AM" && h === 12) h = 0;
  return h * 60 + min;
}

function formatTime(mins: number): string {
  let h = Math.floor(mins / 60);
  const m = mins % 60;
  const ap = h >= 12 ? "PM" : "AM";
  h = h % 12; if (h === 0) h = 12;
  return `${h}:${m.toString().padStart(2, "0")} ${ap}`;
}
