# Ride Scheduler — Setup Guide

A weekly scheduling helper for the Park Avenue Community Center Senior
Nutrition with Transportation program. Built for **Microsoft Excel only** —
all rider information stays inside the one workbook on your computer/OneDrive.
**Nothing is sent to any AI or cloud service.**

---

## What's in this folder

| File | What it is |
|---|---|
| `Ride Scheduler.xlsx` | The workbook you actually use. Open this in Excel. |
| `AssembleSchedule.ts` | The one-click button's code. You paste this in once (steps below). |
| `build_workbook.py` | The script that builds the .xlsx (you can ignore it). |
| `SETUP-GUIDE.md` | This file. |

---

## First-time setup (about 15 minutes, once)

### 1. Fill in your riders
Open `Ride Scheduler.xlsx` → **Riders** tab. Replace the sample names with your
real ~10 riders. For each one fill: phone, address, **zone** (N/E/S/W), and
their **usual** pickup and dropoff times. The "usual" times are how the tool
knows when a time is unusual and a rider needs a heads-up call.

### 2. Install the one-click button
1. In Excel, go to the **Automate** tab.
2. Click **New Script**.
3. Delete the sample code, then open `AssembleSchedule.ts`, copy **everything**,
   and paste it in.
4. Click **Save**, and rename the script **Assemble Schedule**.
5. *(Optional but nice)* Automate tab → `...` menu → **Add to ribbon** so it's
   always one click.

> No "Automate" tab? You need Excel for the web (free with your work account at
> office.com) or Excel on Microsoft 365 desktop. Office Scripts is included —
> no extra license needed.

---

## Every week (a few minutes)

1. Open the **Requests** tab. Clear last week's rows.
2. Type in each rider's days and times from their paper schedules
   (pick the name and day from the dropdowns; type times like `10:30 AM`).
   - Leave a time blank if they don't need that direction that day.
   - Use the **Note** column for one-offs ("doctor appt first").
3. Click **Assemble Schedule** (Automate tab).
4. Open **Schedule** → grouped by Day, then Zone, then Time. Print it for drivers.
5. Open **Notify** → the call list of only the riders whose time changed this
   week, with their usual vs. this-week time. Work down the list and check them off.

That's it. The multi-hour compile becomes type-in + one click.

---

## How it decides things

- **Grouping:** trips sort by Day → Zone (N, E, S, W) → Time, so geographically
  close riders land together in time order — an easy starting point for routing.
  For 10 riders you finish the last bit of sequencing by eye.
- **Heads-up flag:** if a rider's pickup or dropoff differs from their *usual*
  time by more than **15 minutes**, it's flagged ⚠ and added to **Notify**.
  Change `FLAG_MINUTES` at the top of the script to make it stricter/looser.

---

## Where AI fits (safely)

The scheduling itself needs **no AI** — it's just sorting, which keeps senior
data fully private. Use your **Copilot Chat** only for generic, no-names text:

- *"Write a warm, brief phone script telling a senior their pickup is 30 minutes
  earlier than usual on Tuesday."*
- *"Draft a one-paragraph notice for riders that the center is closed July 4."*

Paste those drafts back into Outlook/Word. **Never paste rider names, addresses,
or phone numbers into Copilot Chat** — keep that in this workbook.

---

## Ideas for later (if this helps)

- A **Microsoft Form** for staff/family to submit ride requests straight into the
  Requests tab — cuts paper transcription.
- A **Power Automate** flow to email/text the Notify list automatically.
- A monthly **totals** tab for County/grant reporting (meals + rides served).

Tell me which one to build next.
