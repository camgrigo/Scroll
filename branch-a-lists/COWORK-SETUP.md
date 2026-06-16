# Cowork-driven setup — paste these prompts into Claude Cowork

This guide lets **Claude Cowork** (Anthropic's desktop agent) do the clicking for
you: it imports the list, sets the columns, builds the views, and builds the
email flow in Microsoft 365. You paste each prompt below into Cowork **in order**,
watch it work, and correct it in plain language if it gets a step wrong.

> **You drive Cowork; Cowork drives Microsoft 365.** Run each prompt, let Cowork
> finish and show you the result, then move to the next.

---

## 🔒 Privacy guardrail — read first

**Cowork is Anthropic, not Microsoft.** Your rule is that real rider names,
addresses, and phone numbers stay inside Microsoft 365 (only Microsoft Copilot
may touch them). So:

- ✅ **Cowork builds the structure** — columns, views, flow — using the **fake
  sample riders** already in `Schedule for Lists Import.xlsx`. That sample data is
  invented, so it's safe.
- ✅ **Staff emails are fine** to give Cowork (Driver 1/2, FACT Coordinator,
  Supervisor) — those are coworkers, not riders.
- ❌ **Never have Cowork enter real riders.** After the structure is built, *you*
  delete the samples and type real riders directly in M365 (last section). Do not
  paste real rider PII into Cowork.

---

## Before you start

1. Open **Claude Cowork** on your desktop.
2. Make sure Cowork can reach this repo folder (`branch-a-lists/`) — it will open
   the reference files (`LIST-SCHEMA.md`, `views.md`, `power-automate-flow.md`,
   `email-template.md`, `column-formatting/*.json`,
   `Schedule for Lists Import.xlsx`).
3. In the browser Cowork will control, **sign in to Microsoft 365**
   (office.com) with your work account so Lists and Power Automate are reachable.
4. Have the **4 real staff email addresses** ready (for Prompt 3): Driver 1,
   Driver 2, FACT Coordinator, Supervisor.

---

## Prompt 1 — Create the list and its columns

```
You're helping me set up a Microsoft List for a senior-rides scheduler.
Open the reference file branch-a-lists/LIST-SCHEMA.md and follow it exactly.

Steps:
1. Go to office.com (I'm already signed in) and open Microsoft Lists.
2. Create a new list FROM EXCEL, uploading the file
   branch-a-lists/Schedule for Lists Import.xlsx.
3. In the import preview, set each column's type to match LIST-SCHEMA.md:
   - Assigned Driver = Choice with exactly: Driver 1, Driver 2, FACT Coordinator,
     Supervisor
   - Outside Ride (FACT/Lyft) = Yes/No (default No)
   - Pickup Time and Return Time = Date and time (show the time)
   - Day, Zone, Trip Type = Choice with the options listed in LIST-SCHEMA.md
4. Name the list: Senior Rides Schedule. Create it.
5. Rename the built-in "Title" column to "Rider".
6. Apply column colors: for Zone, Outside Ride (FACT/Lyft), and Trip Type, use
   "Format this column → Advanced mode" and paste the matching JSON from
   branch-a-lists/column-formatting/ (zone-color.json, outside-ride-color.json,
   trip-type-color.json).

Take a screenshot after each major step and confirm the 10 sample rows show with
colored pills. Stop and ask me if any column type won't set correctly.
```

---

## Prompt 2 — Build the 4 views

```
Now build four views on the "Senior Rides Schedule" list. Open
branch-a-lists/views.md and follow it. Create these:

1. Calendar — calendar view; Start date = Pickup Time, End date = Return Time;
   title = Rider, subtitle = Zone.
2. By Driver — list view; group by Assigned Driver; sort by Day then Pickup Time;
   FILTER to Outside Ride (FACT/Lyft) = No (van runs only).
3. By Day — list view; group by Day; sort by Zone then Pickup Time.
4. FACT / Lyft riders — list view; FILTER to Outside Ride (FACT/Lyft) = Yes;
   sort by Day then Pickup Time.

Save each one and show me the resulting tabs. Confirm "By Driver" hides the
FACT/Lyft sample rows and "FACT / Lyft riders" shows only them.
```

---

## Prompt 3 — Build the per-driver email flow

```
Build a Power Automate flow that emails each person their own slice of the
schedule. Open branch-a-lists/power-automate-flow.md and
branch-a-lists/email-template.md and follow them exactly.

Key points:
- It's a SCHEDULED (Recurrence) flow.
- First action: initialize an Object variable "roleEmails" mapping each role to a
  real address. I will give you the four addresses now:
  Driver 1 = <paste>, Driver 2 = <paste>,
  FACT Coordinator = <paste>, Supervisor = <paste>.
  (These are staff emails — fine to use.)
- Get items from "Senior Rides Schedule", then four branches:
  * Driver 1: filter Assigned Driver = Driver 1 AND Outside Ride = No → HTML table
    → email to roleEmails['Driver 1'] using the driver digest body.
  * Driver 2: same as above for Driver 2.
  * FACT Coordinator: filter Outside Ride = Yes → email the FACT/Lyft list body.
  * Supervisor: all rows → email the supervisor summary body.
- Use only standard connectors (no premium).

Build it, save it, and show me the flow overview. Don't run it yet.
```

---

## Prompt 4 — Test run

```
Do a test run of the flow (Test → Manually → Run) using the current sample rows.
Then check the four resulting emails and tell me:
- Did Driver 1 and Driver 2 each get only their own van runs (no FACT/Lyft rows)?
- Did the FACT Coordinator get only the Outside Ride = Yes riders?
- Did the Supervisor get all rows?
Report any step that errored in the run history and what it said.
```

---

## What YOU do next (not Cowork) — add real riders

Once the structure and flow are confirmed working on the sample data, finish in
Microsoft 365 **yourself**, with Cowork closed or idle:

1. In the list, delete the 10 sample rows.
2. Click **+ New** and enter each real rider/day with the form (dropdowns for
   Day, Zone, Trip Type, Assigned Driver; Yes/No for Outside Ride; times).
3. For a FACT/Lyft rider, set **Outside Ride = Yes** and **Assigned Driver =
   FACT Coordinator**.

> This is the only step with real rider PII, so it stays entirely inside M365.
> **Do not ask Cowork to do it.**

---

## Tips for working with Cowork

- Let Cowork take a screenshot and confirm after each step before continuing.
- If a column comes in as the wrong type, just tell it in plain language:
  *"Outside Ride should be a Yes/No column, not text — fix it."*
- Keep the Microsoft 365 browser tab in focus while Cowork works.
- If Cowork gets stuck on a screen, the manual fallback for that exact step is in
  `SETUP-GUIDE.md` / `LIST-SCHEMA.md` / `views.md` / `power-automate-flow.md`.
