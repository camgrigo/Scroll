# Copilot prompts (step F)

Ready-to-paste prompts for **Microsoft Copilot** to help with the senior rides
schedule. These are grouped by job: **weekly summary**, **rider notices**, and
**conflict / double-booking spotting**.

> **Privacy / data boundary:** use **Copilot inside your Microsoft 365**
> (Copilot in Lists/SharePoint, Copilot Chat with "Work" scope, or Copilot in
> Outlook/Word). Run on **this list's data**, which stays inside your tenant.
> **Never paste rider names, addresses, or phone numbers into any non-Microsoft
> AI** (ChatGPT, Gemini, etc.). If you're using the *personal*/web Copilot
> without a work account, keep prompts generic and **do not include real PII** —
> use the "no-names" versions noted below.

---

## ⚠️ The honest limitation (read first)

**Copilot is NOT a route optimizer.** It cannot work out the best driving order,
shortest path, or van assignments. It does not know real drive times or traffic.
What it CAN do here:

- **summarize** what's already in your list,
- **draft** friendly text (notices, call scripts),
- **flag obvious conflicts** it can see in the data (same driver, two rides at
  the same time; two riders with identical pickup time/zone; missing driver).

Treat anything Copilot says about "conflicts" as a **prompt to look**, not a
final answer — you confirm by eye. Real best-sequence routing is the separate
branch noted in the setup guide.

---

## 1. Weekly summary

**Where:** Copilot in Lists (the Copilot button on the list), or Copilot Chat
(Work scope) pointed at the list.

- *"Summarize this week's rides from the Senior Rides Schedule list. Group by
  Day, and within each day list how many riders, which zones, and which driver
  is assigned. Keep it to a short bulleted list."*

- *"How many total rides are scheduled this week, and how many are van runs vs.
  FACT vs. Lyft? Give me the counts only."*

- *"List each driver and the number of runs assigned to them this week, sorted
  from most to fewest."*

- *"Which days have the most rides? Tell me if any day looks unusually heavy
  compared to the others."*

---

## 2. Drafting rider notices and call scripts

**Where:** Copilot in **Outlook** or **Word** is ideal (you're writing a
message). These produce *generic* text — fill in the specific name/time yourself
when you send, so you don't need to put PII into the prompt.

- *"Write a warm, brief phone-call script telling a senior rider their pickup
  time has changed this week. Leave blanks for [name], [old time], and [new
  time]. Keep it under 60 words and easy to read aloud."*

- *"Draft a short, friendly notice that the Community Center will be closed on
  [date] and there will be no rides or lunch that day. One short paragraph."*

- *"Write a reminder message for riders to confirm their rides for next week by
  calling the center. Friendly, one paragraph, suitable for a printed flyer."*

- *"Rewrite this note so it's clear for someone hard of hearing — short
  sentences, simple words: [paste your draft]."*

> If you're on **work Copilot** and want it to pull the real details, you can
> say: *"Using the Senior Rides Schedule list, draft a heads-up note for the
> rider whose pickup time changed the most this week."* This stays in the
> boundary. On **personal/web Copilot, do not do this** — keep names out.

---

## 3. Conflict / double-booking spotting

**Where:** Copilot in Lists or Copilot Chat (Work scope) on the list.

- *"In the Senior Rides Schedule list, find any cases where the same Assigned
  Driver has two rides with overlapping Pickup Time and Return Time on the same
  Day. List them so I can check."*

- *"Show me any two riders on the same Day with the exact same Pickup Time —
  these might be double-booked. List the rider names, times, and zones."*

- *"List any rides that are missing an Assigned Driver, missing a Pickup Time,
  or missing a Zone, so I can fill them in."*

- *"Are there any rides where the Return Time is earlier than the Pickup Time?
  Those are likely typos — list them."*

- *"Group this week's rides by Zone and tell me if any one driver is covering
  zones that are far apart on the same day, so I can rebalance by hand."*

> Remember: the last prompt **flags** a possible inefficiency — it does **not**
> compute the better route. You decide the actual van order.

---

## Quick copy block (paste any of these)

```
Summarize this week's rides from the Senior Rides Schedule list, grouped by Day,
with rider count, zones, and assigned driver per day. Short bullets.
```
```
List each driver and how many runs they have this week, most to fewest.
```
```
Find same-driver overlapping rides and same-time same-day riders in the Senior
Rides Schedule list — these may be double-bookings. List them for me to verify.
```
```
List rides missing an Assigned Driver, Pickup Time, or Zone.
```
```
Write a warm 50-word phone script telling a rider their pickup time changed.
Leave blanks for [name], [old time], [new time].
```
