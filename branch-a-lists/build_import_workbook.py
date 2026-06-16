"""
Generates "Schedule for Lists Import.xlsx" for the Park Avenue Community Center
Senior Nutrition with Transportation program — Branch A (Microsoft Lists).

Run:    python3 build_import_workbook.py
Output: Schedule for Lists Import.xlsx   (import this into Microsoft Lists)

Why this file exists
--------------------
Microsoft Lists can create a brand-new list FROM an Excel file, and it will try
to guess each column's type from the data it sees. To make those guesses good,
this script writes ONE clean sheet as a proper Excel Table with:
  - header names that match the List column names EXACTLY (step B of the plan),
  - the right kind of value in every cell (real dates/times, Yes/No, clean
    Choice words), so Lists infers Date and time / Choice / Yes-No correctly.

All data here is INVENTED sample data for Escondido, CA. Replace it with your
real riders after the list is created. Rider names + zones are reused from the
earlier ride-scheduler tool so the two tools line up.

Note on "Person" columns
-------------------------
"Assigned Driver" is meant to become a *Person* column in Lists. Excel import
cannot create a Person column directly (it has no link to your org directory),
so we import the driver as plain text here and the SETUP/LIST-SCHEMA guides
show how to either (a) add a real Person column in Lists afterward, or
(b) keep it as a Choice column of driver names. The text we write here is just
a first/last name that is easy to match to a real account later.
"""

from datetime import datetime, time
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.worksheet.table import Table, TableStyleInfo
from openpyxl.utils import get_column_letter

# ---- palette (kept consistent with the ride-scheduler tool) --------------
NAVY  = "1F3864"
BLUE  = "2E5496"
WHITE = "FFFFFF"
thin  = Side(style="thin", color="BFBFBF")
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)

# ---- the exact List column names, in order (step B) ----------------------
# Header text MUST match the List display names exactly.
COLUMNS = [
    # (header, excel width, kind)  kind drives formatting only
    ("Rider",            22, "text"),
    ("Pickup Address",   30, "text"),
    ("Day",              10, "choice"),
    ("Zone",             10, "choice"),
    ("Trip Type",        12, "choice"),
    ("Pickup Time",      16, "datetime"),
    ("Destination",      26, "text"),
    ("Return Time",      16, "datetime"),
    ("Assigned Driver",  18, "text"),
    ("Ride Provider",    14, "choice"),   # None / FACT / Lyft  (the FACT/Lyft flag)
    ("Notes",            28, "text"),
]

# A fixed reference date so Lists infers a real Date-and-time column.
# We use the current week's Monday-style placeholder; the date part does not
# matter to the user (they read the time), but it must be a real datetime so
# Lists picks "Date and time", not text.
D = datetime(2026, 6, 15)  # a Monday

def dt(hh, mm):
    """Return a real datetime on the reference date (so Lists sees Date/time)."""
    return datetime(D.year, D.month, D.day, hh, mm)

# ---- sample rows ---------------------------------------------------------
# Columns line up with COLUMNS above.
# Riders/zones reused from ride-scheduler; addresses are plausible Escondido.
# DEST: most go to the center; one shows a different destination.
CENTER = "Park Avenue Community Center"
ROWS = [
    # Rider,           Pickup Address,          Day,   Zone, Trip,    Pickup,    Destination, Return,    Driver,    Provider, Notes
    ("Dorothy Alvarez","412 N Ash St",          "Mon", "N", "Round trip", dt(10,30), CENTER, dt(12,45), "Robert Nguyen", "None", "Walker"),
    ("Frank Bishop",   "905 E Mission Ave",     "Mon", "E", "Round trip", dt(10,45), CENTER, dt(13,0),  "Robert Nguyen", "None", ""),
    ("Gloria Chen",    "233 S Juniper St",      "Mon", "S", "Round trip", dt(10,30), CENTER, dt(12,45), "Maria Lopez",   "None", "Low sodium"),
    ("Harold Diaz",    "78 W 9th Ave",          "Tue", "W", "Round trip", dt(11,0),  CENTER, dt(13,0),  "Maria Lopez",   "None", "Cane"),
    ("Irene Edwards",  "1521 N Broadway",       "Tue", "N", "Round trip", dt(10,30), CENTER, dt(12,45), "Robert Nguyen", "None", ""),
    ("James Fletcher", "640 E Grand Ave",       "Wed", "E", "Round trip", dt(10,45), CENTER, dt(13,0),  "Maria Lopez",   "None", "Wheelchair lift"),
    ("Karen Gomez",    "318 S Escondido Blvd",  "Wed", "S", "Round trip", dt(10,30), CENTER, dt(12,45), "Robert Nguyen", "None", ""),
    ("Leonard Hayes",  "55 W Lincoln Ave",      "Thu", "W", "Round trip", dt(11,0),  CENTER, dt(13,0),  "Maria Lopez",   "FACT", "FACT paratransit booked"),
    ("Marie Ingram",   "1208 N Centre City Pkwy","Thu","N", "Round trip", dt(10,30), CENTER, dt(12,45), "Robert Nguyen", "None", "Hard of hearing"),
    ("Nathan Jones",   "402 E Valley Pkwy",     "Fri", "E", "Pickup only", dt(10,45), CENTER, None,      "Maria Lopez",   "Lyft", "Lyft home after lunch"),
]

# ---- build workbook ------------------------------------------------------
wb = Workbook()
ws = wb.active
ws.title = "Schedule"

# header row
for ci, (name, width, _kind) in enumerate(COLUMNS, start=1):
    c = ws.cell(row=1, column=ci, value=name)
    c.font = Font(bold=True, color=WHITE)
    c.fill = PatternFill("solid", fgColor=BLUE)
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = BORDER
    ws.column_dimensions[get_column_letter(ci)].width = width

# data rows
for ri, row in enumerate(ROWS, start=2):
    for ci, (val, (_name, _w, kind)) in enumerate(zip(row, COLUMNS), start=1):
        c = ws.cell(row=ri, column=ci, value=val)
        c.border = BORDER
        c.alignment = Alignment(vertical="center",
                                horizontal="center" if kind in ("choice", "datetime") else "left",
                                indent=0 if kind in ("choice", "datetime") else 1)
        if kind == "datetime" and isinstance(val, datetime):
            # show a clean time so the human preview reads naturally;
            # Lists reads the underlying datetime, not this display string.
            c.number_format = "h:mm AM/PM"

ws.row_dimensions[1].height = 28
ws.freeze_panes = "A2"

# Make it a real Excel Table named "Schedule" — Lists imports tables cleanly.
last_col = get_column_letter(len(COLUMNS))
last_row = 1 + len(ROWS)
table = Table(displayName="ScheduleImport", ref=f"A1:{last_col}{last_row}")
table.tableStyleInfo = TableStyleInfo(
    name="TableStyleMedium2", showFirstColumn=False, showLastColumn=False,
    showRowStripes=True, showColumnStripes=False)
ws.add_table(table)

wb.save("Schedule for Lists Import.xlsx")
print("Wrote Schedule for Lists Import.xlsx")
print("Columns:", [c[0] for c in COLUMNS])
print("Rows:", len(ROWS))
