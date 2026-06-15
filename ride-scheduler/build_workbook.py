"""
Generates "Ride Scheduler.xlsx" for the Park Avenue Community Center
Senior Nutrition with Transportation weekly scheduling workflow.

Run:  python3 build_workbook.py
Output: Ride Scheduler.xlsx  (open in Excel)

Design goals
- All senior PII stays inside this single workbook (no cloud / no AI service).
- Two sheets you type into (Riders once, Requests weekly).
- Two sheets the one-click Office Script fills in (Schedule, Notify).
- Works even WITHOUT the script: the input sheets are plain tables you can
  sort and read by hand for 10 riders.
"""

from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.utils import get_column_letter

# ---- palette -------------------------------------------------------------
NAVY   = "1F3864"
BLUE   = "2E5496"
LIGHT  = "D9E1F2"
INPUT  = "FFF2CC"   # cells you type into = soft yellow
GEN    = "E2EFDA"   # generated cells = soft green
GREY   = "808080"
WHITE  = "FFFFFF"
FLAG   = "FCE4D6"   # flagged "unusual time" = soft orange

thin = Side(style="thin", color="BFBFBF")
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)

def header(cell, text, fill=BLUE, color=WHITE, size=11):
    cell.value = text
    cell.font = Font(bold=True, color=color, size=size)
    cell.fill = PatternFill("solid", fgColor=fill)
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    cell.border = BORDER

def title(ws, text, span):
    ws.merge_cells(f"A1:{get_column_letter(span)}1")
    c = ws["A1"]
    c.value = text
    c.font = Font(bold=True, color=WHITE, size=16)
    c.fill = PatternFill("solid", fgColor=NAVY)
    c.alignment = Alignment(horizontal="left", vertical="center", indent=1)
    ws.row_dimensions[1].height = 32

wb = Workbook()

# =========================================================================
# 1. READ ME
# =========================================================================
ws = wb.active
ws.title = "Read Me"
title(ws, "Ride Scheduler  —  How to use this workbook", 8)
ws.column_dimensions["A"].width = 3
ws.column_dimensions["B"].width = 100

lines = [
    ("", ""),
    ("step", "EVERY WEEK — 3 steps"),
    ("num", "1.  Open the 'Requests' tab. Type in each rider's days and times from their paper schedule."),
    ("num", "2.  Click the 'Assemble Schedule' button (Automate tab) — OR sort the table by Zone then Time by hand."),
    ("num", "3.  Open 'Schedule' to print driver runs, and 'Notify' for the call list of changed times."),
    ("", ""),
    ("step", "SET UP ONCE"),
    ("num", "•  Fill the 'Riders' tab with all ~10 riders: address, zone, phone, and their usual (preferred) times."),
    ("num", "•  Install the one-click button: Excel  >  Automate  >  New Script  >  paste AssembleSchedule.ts  >  Save."),
    ("", ""),
    ("step", "COLOR KEY"),
    ("input", "   Yellow cells = you type here."),
    ("gen",   "   Green cells = filled in automatically (don't type here)."),
    ("flag",  "   Orange = a time that differs from the rider's usual time (they need a heads-up call)."),
    ("", ""),
    ("step", "PRIVACY"),
    ("plain", "All rider information stays inside THIS file on your computer/OneDrive. Nothing is sent to any AI"),
    ("plain", "service. The 'Assemble Schedule' button runs locally inside Excel."),
    ("", ""),
    ("step", "ADJUSTING THE 'UNUSUAL TIME' SENSITIVITY"),
    ("plain", "By default, a time is flagged if it differs from the rider's usual time by more than 15 minutes."),
    ("plain", "Change FLAG_MINUTES at the top of the script to make it stricter or looser."),
]
r = 3
for kind, text in lines:
    c = ws.cell(row=r, column=2, value=text)
    if kind == "step":
        c.font = Font(bold=True, color=NAVY, size=12)
    elif kind == "num":
        c.font = Font(size=11)
    elif kind == "input":
        c.font = Font(size=11); c.fill = PatternFill("solid", fgColor=INPUT)
    elif kind == "gen":
        c.font = Font(size=11); c.fill = PatternFill("solid", fgColor=GEN)
    elif kind == "flag":
        c.font = Font(size=11); c.fill = PatternFill("solid", fgColor=FLAG)
    else:
        c.font = Font(size=11, color=GREY)
    r += 1

# =========================================================================
# 2. RIDERS  (set up once)
# =========================================================================
ws = wb.create_sheet("Riders")
cols = [
    ("Rider", 22), ("Phone", 16), ("Address", 30), ("Zone", 8),
    ("Usual Pickup", 14), ("Usual Dropoff", 14), ("Notes (mobility / diet)", 30),
]
title(ws, "Riders  —  master list (set up once, update as needed)", len(cols))
for i, (name, width) in enumerate(cols, start=1):
    header(ws.cell(row=2, column=i), name)
    ws.column_dimensions[get_column_letter(i)].width = width

sample_riders = [
    ("Dorothy Alvarez", "760-555-0142", "412 N Ash St",        "N", "10:30 AM", "12:45 PM", "Walker"),
    ("Frank Bishop",    "760-555-0188", "905 E Mission Ave",   "E", "10:45 AM", "1:00 PM",  ""),
    ("Gloria Chen",     "760-555-0173", "233 S Juniper St",    "S", "10:30 AM", "12:45 PM", "Low sodium"),
    ("Harold Diaz",     "760-555-0119", "78 W 9th Ave",        "W", "11:00 AM", "1:00 PM",  "Cane"),
    ("Irene Edwards",   "760-555-0150", "1521 N Broadway",     "N", "10:30 AM", "12:45 PM", ""),
    ("James Fletcher",  "760-555-0167", "640 E Grand Ave",     "E", "10:45 AM", "1:00 PM",  "Wheelchair lift"),
    ("Karen Gomez",     "760-555-0134", "318 S Escondido Blvd","S", "10:30 AM", "12:45 PM", ""),
    ("Leonard Hayes",   "760-555-0191", "55 W Lincoln Ave",    "W", "11:00 AM", "1:00 PM",  ""),
    ("Marie Ingram",    "760-555-0125", "1208 N Centre City",  "N", "10:30 AM", "12:45 PM", "Hard of hearing"),
    ("Nathan Jones",    "760-555-0146", "402 E Valley Pkwy",   "E", "10:45 AM", "1:00 PM",  ""),
]
for ridx, row in enumerate(sample_riders, start=3):
    for cidx, val in enumerate(row, start=1):
        c = ws.cell(row=ridx, column=cidx, value=val)
        c.border = BORDER
        c.alignment = Alignment(vertical="center",
                                horizontal="center" if cidx in (2,4,5,6) else "left",
                                indent=0 if cidx in (2,4,5,6) else 1)
        if cidx == 4:  # zone
            c.font = Font(bold=True)
ws.freeze_panes = "A3"

# zone dropdown on Riders
dv_zone = DataValidation(type="list", formula1='"N,E,S,W"', allow_blank=True)
ws.add_data_validation(dv_zone)
dv_zone.add(f"D3:D200")

# =========================================================================
# 3. REQUESTS  (fill in weekly)
# =========================================================================
ws = wb.create_sheet("Requests")
cols = [("Rider", 22), ("Day", 12), ("Pickup Time", 14), ("Dropoff Time", 14), ("Note for this day", 28)]
title(ws, "Requests  —  type this in each week from the paper schedules", len(cols))
for i, (name, width) in enumerate(cols, start=1):
    header(ws.cell(row=2, column=i), name, fill=BLUE)
    ws.column_dimensions[get_column_letter(i)].width = width
    # mark the input columns yellow header tint via a note row look
# sample week (a few entries so the user sees the shape; delete & replace)
sample_requests = [
    ("Dorothy Alvarez", "Mon", "10:30 AM", "12:45 PM", ""),
    ("Dorothy Alvarez", "Wed", "10:30 AM", "12:45 PM", ""),
    ("Frank Bishop",    "Mon", "10:45 AM", "1:00 PM",  ""),
    ("Frank Bishop",    "Tue", "9:15 AM",  "1:00 PM",  "Doctor appt first"),
    ("Gloria Chen",     "Wed", "10:30 AM", "12:45 PM", ""),
    ("Harold Diaz",     "Thu", "11:00 AM", "1:00 PM",  ""),
    ("Irene Edwards",   "Fri", "10:30 AM", "12:45 PM", ""),
]
for ridx, row in enumerate(sample_requests, start=3):
    for cidx, val in enumerate(row, start=1):
        c = ws.cell(row=ridx, column=cidx, value=val)
        c.border = BORDER
        c.fill = PatternFill("solid", fgColor=INPUT)
        c.alignment = Alignment(vertical="center",
                                horizontal="center" if cidx in (2,3,4) else "left",
                                indent=0 if cidx in (2,3,4) else 1)
# pre-format empty input rows so it's obvious where to type
for ridx in range(3 + len(sample_requests), 80):
    for cidx in range(1, len(cols)+1):
        c = ws.cell(row=ridx, column=cidx)
        c.border = BORDER
        c.fill = PatternFill("solid", fgColor=INPUT)
ws.freeze_panes = "A3"

# dropdowns: Rider (from Riders sheet) and Day
dv_rider = DataValidation(type="list", formula1="=Riders!$A$3:$A$200", allow_blank=True)
ws.add_data_validation(dv_rider)
dv_rider.add("A3:A80")
dv_day = DataValidation(type="list", formula1='"Mon,Tue,Wed,Thu,Fri"', allow_blank=True)
ws.add_data_validation(dv_day)
dv_day.add("B3:B80")

# =========================================================================
# 4. SCHEDULE  (generated)
# =========================================================================
ws = wb.create_sheet("Schedule")
cols = [("Day", 10), ("Zone", 8), ("Time", 10), ("Trip", 12), ("Rider", 22),
        ("Phone", 16), ("Address", 30), ("Heads-up?", 12), ("Note", 26)]
title(ws, "Schedule  —  generated. Click 'Assemble Schedule', then print by Day.", len(cols))
for i, (name, width) in enumerate(cols, start=1):
    header(ws.cell(row=2, column=i), name, fill=BLUE)
    ws.column_dimensions[get_column_letter(i)].width = width
note = ws.cell(row=3, column=1, value="(Press the Assemble Schedule button — results appear here)")
note.font = Font(italic=True, color=GREY)
ws.merge_cells("A3:I3")
ws.freeze_panes = "A3"

# =========================================================================
# 5. NOTIFY  (generated)
# =========================================================================
ws = wb.create_sheet("Notify")
cols = [("Rider", 22), ("Phone", 16), ("Day", 10), ("Trip", 12),
        ("Usual Time", 12), ("This Week", 12), ("Difference", 14), ("Called? ✓", 12)]
title(ws, "Notify  —  call list: riders whose time changed this week", len(cols))
for i, (name, width) in enumerate(cols, start=1):
    header(ws.cell(row=2, column=i), name, fill=BLUE)
    ws.column_dimensions[get_column_letter(i)].width = width
note = ws.cell(row=3, column=1, value="(Generated with the schedule — only riders needing a heads-up appear here)")
note.font = Font(italic=True, color=GREY)
ws.merge_cells("A3:H3")
ws.freeze_panes = "A3"

wb.save("Ride Scheduler.xlsx")
print("Wrote Ride Scheduler.xlsx")
