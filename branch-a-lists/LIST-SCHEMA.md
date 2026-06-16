# List Schema — "Senior Rides Schedule"

This is the exact blueprint for the Microsoft List. **All rider data stays
inside your Microsoft 365 (the data boundary) — nothing leaves to any outside
AI or service.**

You will create this list **once** by importing the file
`Schedule for Lists Import.xlsx`. Lists will guess each column's type from the
sample data. The table below is the *target* — after importing, check each
column against this table and fix any type Lists guessed wrong (how-to is at the
bottom).

---

## The columns (this is "step B" of the plan)

| # | List column name | Lists column TYPE | Choices / format | Required? | Default |
|---|---|---|---|---|---|
| 1 | **Rider** | Single line of text | (free text — rider's name) | Yes | — |
| 2 | **Pickup Address** | Single line of text | (free text — street address) | Yes | — |
| 3 | **Day** | Choice | Mon, Tue, Wed, Thu, Fri | Yes | (none) |
| 4 | **Zone** | Choice | N, E, S, W | Yes | (none) |
| 5 | **Trip Type** | Choice | Round trip, Pickup only, Return only | Yes | Round trip |
| 6 | **Pickup Time** | Date and time | Show **time** (date shown too is fine) | No | (none) |
| 7 | **Destination** | Single line of text | (free text — usually "Park Avenue Community Center") | No | Park Avenue Community Center |
| 8 | **Return Time** | Date and time | Show **time** | No | (none) |
| 9 | **Assigned Driver** | **Person or Group** | (pick from your org's people) | No | (none) |
| 10 | **Ride Provider** | Choice | None, FACT, Lyft | Yes | None |
| 11 | **Notes** | Multiple lines of text (plain) | (free text — mobility, one-offs) | No | (none) |

> **"Title" column:** Every new SharePoint/Lists list starts with a built-in
> column called **Title**. The cleanest approach is to **rename Title → Rider**
> so the rider's name is the first, bold, clickable column. The setup guide
> shows this. If you instead keep Title separate, just hide it.

---

## Why each type was chosen (plain English)

- **Choice** (Day, Zone, Trip Type, Ride Provider) gives you a fixed dropdown.
  No typos, and it powers the colored views and the grouped views. This is a
  big error-reducer versus typing free text.
- **Date and time** (Pickup Time, Return Time) lets Lists drive the **Calendar
  view** and lets Power Automate compare times. If these came in as plain text,
  the calendar and the flow would not work.
- **Person or Group** (Assigned Driver) links to a *real* person in your
  organization. That's what lets the flow email "the assigned driver"
  automatically — Lists already knows their email.
- **Ride Provider** is the **FACT/Lyft flag** (step G). Using a 3-way Choice
  (None / FACT / Lyft) is better than a Yes/No because you have two outside
  providers, not one. If you only ever use one, a **Yes/No** column named
  "Outside ride?" would also be valid — pick one and stay consistent.

---

## Click-path: create the list by importing the Excel file (step A)

> Do this once. Time: about 5 minutes.

1. Go to **https://lists.live.com** *(personal)* — **or, for work, open
   Microsoft 365 → the app launcher (the 9-dots, top-left) → Lists.**
2. Click **+ New list**.
3. Choose **From Excel**.
4. Click **Upload file** and pick **`Schedule for Lists Import.xlsx`** from this
   folder (or select it from OneDrive/SharePoint if you saved it there first).
5. Lists shows a **preview grid**. At the top of each column is a little
   **type dropdown** (it says things like "Single line of text", "Choice",
   "Date and time"). **Check each one against the table above** and change any
   that are wrong *right here* — it's easiest to fix now. (Common fix: a time
   column comes in as "Single line of text" — switch it to "Date and time".)
6. Make sure the **first row is treated as headers** (Lists usually detects
   this; there's a toggle if not).
7. Name the list **`Senior Rides Schedule`**. Optionally add a description and
   pick a color/icon.
8. Click **Create**. Your list appears with the 10 sample rows.

---

## Fixing column types Lists guessed wrong (after import)

If you didn't catch a wrong type in the preview, fix it after the list exists:

1. Click the **column header** → **Column settings** → **Edit**.
2. The right panel lets you change the **Type** and its options.

Specific fixes you will likely need:

### A. Turn **Assigned Driver** into a Person column
Excel import cannot create a Person column (Excel has no link to your org's
people), so it will come in as **text**. To get the real benefit (auto-email
the driver), replace it:
1. Note the driver names already in the text column.
2. **+ Add column → Person** → name it **Assigned Driver (Person)** →
   allow selecting **People only**, single selection → **Save**.
3. For each row, open the item and pick the real driver account.
4. Once filled, delete the old text column, then rename the new one to
   **Assigned Driver**.

> **Simpler alternative if your drivers don't all have M365 accounts:** keep
> **Assigned Driver** as a **Choice** column listing your drivers' names
> (e.g., Robert Nguyen, Maria Lopez). The flow can still email them if you map
> each name to an email address inside the flow. The setup guide explains both
> paths; pick one.

### B. Confirm the Choice columns
For **Day, Zone, Trip Type, Ride Provider**: open Edit and make sure the
**Choices** list matches the table exactly (add any missing options, e.g. make
sure **Ride Provider** has all of None / FACT / Lyft). Set the **Default value**
shown in the table. Turn **Require that this column contains information** = Yes
for the ones marked Required.

### C. Confirm the Date columns
For **Pickup Time** and **Return Time**: Edit → Type = **Date and Time** →
under "Show", choose to display the **time**. (Showing the date too is fine.)

---

## Column-formatting JSON (colors)

Optional but recommended — these make zones and providers pop at a glance.
The JSON files live in `column-formatting/` and are applied per column:
**column header → Column settings → Format this column → Advanced mode →
paste JSON → Save.**

| Column | File | Effect |
|---|---|---|
| Zone | `column-formatting/zone-color.json` | N=blue, E=green, S=gold, W=orange pills |
| Ride Provider | `column-formatting/ride-provider-color.json` | FACT=orange, Lyft=purple, None=grey |
| Trip Type | `column-formatting/trip-type-color.json` | colored pill per trip type |

See `views.md` for the full view setup and where these colors show up.
