# Senior Rides Schedule — Setup Guide (Branch A: Microsoft Lists)

**Everything in this tool stays inside your Microsoft 365 data boundary — your
rider names, addresses, and phone numbers never leave your organization, and
nothing is ever sent to any outside AI service.**

This is the new direction for the Park Avenue Community Center Senior Nutrition
with Transportation program. Instead of an Excel workbook, the master schedule
lives in **Microsoft Lists** — a Microsoft 365 app you already have. You type
rides into a tidy **form**, see them in **calendar / by-driver / by-day** views,
and a **Power Automate** flow emails each driver their runs automatically.

> The earlier Excel tool in `../ride-scheduler/` still works and is **not**
> being deleted. Branch A (this folder) is the agreed next step.

---

## What's in this folder

| File | What it is |
|---|---|
| `SETUP-GUIDE.md` | This file — start here. |
| `LIST-SCHEMA.md` | Exact columns + types, and how to import the Excel into Lists. |
| `Schedule for Lists Import.xlsx` | The clean Excel you import to create the list. |
| `build_import_workbook.py` | The script that builds that .xlsx (you can ignore it). |
| `views.md` | How to build the Calendar, By Driver, By Day, and FACT/Lyft views. |
| `column-formatting/` | Color JSON for Zone, Outside Ride (FACT/Lyft), Trip Type columns. |
| `power-automate-flow.md` | The auto-email / Teams-post flow, step by step. |
| `email-template.md` | The driver email wording. |
| `teams-template.md` | The Teams post / adaptive card. |
| `copilot-prompts.md` | Ready-to-use Copilot prompts (summaries, notices, conflicts). |

---

## How the pieces fit (steps A–G)

| Step | What | Where it's covered |
|---|---|---|
| **A** | Move the schedule into Microsoft Lists (import from Excel) | `LIST-SCHEMA.md` |
| **B** | Deliberate columns with strict types | `LIST-SCHEMA.md` |
| **C** | Type rides in via the built-in **form**, not raw cells | this guide, below |
| **D** | Calendar + By-Driver + By-Day views | `views.md` |
| **E** | Power Automate flow emails drivers / posts to Teams | `power-automate-flow.md` |
| **F** | Copilot prompts for summaries, notices, conflict-spotting | `copilot-prompts.md` |
| **G** | Track FACT/Lyft riders in the same list, own filtered view | `LIST-SCHEMA.md` + `views.md` |

---

## First-time setup (about 30–45 minutes, once)

Do these in order. Each links to the detailed file.

1. **Create the list from Excel.** Follow `LIST-SCHEMA.md` → "Create the list by
   importing the Excel file." This gives you a list called **Senior Rides
   Schedule** with 10 sample rows and the right column types. *(Step A + B)*

2. **Fix any column types Lists guessed wrong** — make **Assigned Driver** a
   **Choice** of the four roles (Driver 1, Driver 2, FACT Coordinator,
   Supervisor) and **Outside Ride (FACT/Lyft)** a **Yes/No** column.
   `LIST-SCHEMA.md` walks through both. *(Step B)*

3. **Apply the colors.** In `views.md` → "Apply the colors", paste the three JSON
   files so Zone, Outside Ride (FACT/Lyft), and Trip Type show colored pills.

4. **Build the four views** — Calendar, By Driver, By Day, FACT/Lyft — following
   `views.md`. *(Steps D + G)*

5. **Build the Power Automate flow** following `power-automate-flow.md` — the
   weekly per-driver email flow. Set the **role → email map** at the top
   (Driver 1, Driver 2, FACT Coordinator, Supervisor → real addresses), then run
   one test. *(Step E)*

6. **Delete the 10 sample rows** and add your real riders (use the form — next
   section).

> No "Lists" app? Open Microsoft 365 (office.com) → the **app launcher** (9 dots,
> top-left) → **Lists**. It's included with your work account; no extra license.

---

## Every week (a few minutes) — your weekly routine

1. **Open the list → "By Day" view.** Clear out last week's rows (select rows →
   delete) or, if rides repeat, just edit the times.

2. **Add each ride with the form (step C — the big error-reducer):**
   - Click **+ New** (top-left of the list). A **form** opens — one field at a
     time, with dropdowns for Day, Zone, Trip Type, and Assigned Driver (the
     four roles), a Yes/No toggle for Outside Ride (FACT/Lyft), and a clock for
     the times.
   - Fill it in, click **Save**. Repeat for each rider/day. For a FACT/Lyft
     rider, set **Outside Ride = Yes** and **Assigned Driver = FACT Coordinator**.
   - Because the form uses dropdowns and required fields, you can't fat-finger a
     zone or forget the driver — that's the point.

3. **Check the Calendar view** for the week at a glance, and the **By Driver**
   view to confirm each driver's load looks balanced.

4. **Run a quick Copilot conflict check** (optional) — paste a prompt from
   `copilot-prompts.md` §3 to flag obvious double-bookings. Confirm by eye.

5. **The weekly flow emails everyone their own slice** — Driver 1 and Driver 2
   each get only their van runs, the FACT Coordinator gets the FACT/Lyft list,
   and the Supervisor gets the full summary. No more print-and-hand-out.

6. **FACT / Lyft riders:** check the **FACT / Lyft riders** view (Outside Ride =
   Yes) so the coordinator confirms those outside bookings. They're kept out of
   the drivers' van-run emails on purpose.

---

## Privacy & data boundary

- The list, the form, the views, the flow, Teams, Outlook, and work Copilot are
  **all Microsoft 365** — rider PII stays inside your organization's boundary.
- **Never paste rider names, addresses, or phone numbers into any non-Microsoft
  AI.** For generic wording, use the no-names prompts in `copilot-prompts.md`.
- Share the list only with the staff/drivers who need it (List → **Share**).

---

## Color key (matches the column-formatting JSON)

| Color | Means |
|---|---|
| 🔵 Blue | Zone **N** / Round trip |
| 🟢 Green | Zone **E** / Pickup only |
| 🟡 Gold | Zone **S** |
| 🟠 Orange | Zone **W** / Return only / **Outside Ride = Yes (FACT/Lyft)** |
| ⚪ Grey | **Outside Ride = No** (your own vans) |

---

## Where Copilot fits (and where it does NOT)

Copilot can **summarize** the week, **draft** rider notices and call scripts, and
**flag obvious conflicts** (same driver double-booked, two riders at the same
time, missing fields). See `copilot-prompts.md`.

**Copilot is NOT a route optimizer.** It cannot compute the best driving order or
assign vans by shortest distance. Use it to summarize and to *flag things to
check* — you make the final routing call by eye, exactly as you do today.

---

## What's confirmed (your answers, baked in)

These reflect the decisions you confirmed — they're built into the sample data,
the schema, the views, and the flow:

1. ✅ **Team = 4 roles:** **Driver 1, Driver 2, FACT Coordinator, Supervisor**.
   "Assigned Driver" is a **Choice** of these roles (placeholder names); the flow
   maps each role to a real email address. No dependency on personal M365
   accounts.
2. ✅ **FACT/Lyft = a simple Yes/No flag** (**Outside Ride (FACT/Lyft)**). "Yes"
   riders are handled by the **FACT Coordinator**, **excluded** from the van
   drivers' emails, and shown in their own **FACT / Lyft riders** view.
3. ✅ **Notifications = per-driver Outlook email** (the primary flow). Each driver
   gets only their own van runs; the FACT Coordinator gets the FACT/Lyft list;
   the Supervisor gets the full weekly summary. **Teams posting is optional.**

Still reasonable defaults you can change any time:

4. **~10 riders, weekdays Mon–Fri**, all going to/from the **Park Avenue
   Community Center** for lunch.
5. **"Round trip"** is the normal case; "Pickup only" / "Return only" exist for
   one-directional days. Adjust the choices if your trip patterns differ.
6. Times are entered as real Date-and-time values so the **calendar** and the
   **flow** work. The sample uses one placeholder Monday; you'll enter real dates.

---

## Known gap / next branch

**True route optimization** — the best pickup order and van assignment by
distance/time — is **not** something Microsoft 365 does cleanly out of the box.
Lists, Copilot, and Power Automate organize, surface, and deliver the schedule,
but they don't compute optimal routes. That's a **separate branch** (it would
need a mapping/routing service such as Azure Maps or a dedicated routing tool,
evaluated for the data boundary). For ~10 riders, grouping by **Zone** then
**Time** (built into the By-Day view) gets you a close, hand-finishable starting
order — the same approach as the original Excel tool.
