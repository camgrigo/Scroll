# Power Automate flow — auto-email drivers & post to Teams (step E)

**Goal:** replace "print the schedule and email/hand it out" with an automatic
flow. When you add or change a ride in the **Senior Rides Schedule** list, the
flow emails the **assigned driver** their run and (optionally) posts a note to a
Teams channel so the schedule change is visible.

**Stays in the boundary:** Power Automate, Lists/SharePoint, Outlook, and Teams
are all Microsoft 365. No rider data leaves your tenant. **No outside AI is
involved in this flow.**

**Connector cost:** everything below uses **standard** connectors
(SharePoint/Lists, Office 365 Outlook, Microsoft Teams). **No premium license is
required.** The one thing that needs care is the **Person** column — see the
"Driver email" note.

---

## Two designs — pick one

| Design | What it does | Best when |
|---|---|---|
| **1. Per-item** *(recommended to start)* | Fires on each ride created/changed; emails that one driver about that one ride; optional Teams post. | Simple, immediate, easy to build. |
| **2. Weekly digest** | A scheduled flow once a week gathers each driver's runs into one email. | You'd rather drivers get ONE email, not many. |

Start with **Design 1**. Design 2 is sketched at the bottom.

---

## Design 1 — Per-item flow (step by step)

### Trigger
- **SharePoint → When an item is created or modified**
- **Site Address:** the site that holds your list
- **List Name:** **Senior Rides Schedule**

> "Created or modified" fires on every save. The condition below stops it from
> spamming on trivial edits.

### Step 1 — Get the driver's email
Because **Assigned Driver** is a **Person** column, the trigger already gives you
the driver's email as dynamic content: **`Assigned Driver Email`**. Use that
directly — no lookup needed.

> **If you kept Assigned Driver as a Choice (text) instead of Person:** add a
> **Switch** (or a small mapping) that turns each driver *name* into an email
> address, e.g. Robert Nguyen → rnguyen@yourorg.org. Then use that variable as
> the "To" address. (Document the name→email map in one place so it's easy to
> update.)

### Step 2 — Condition: only act on real changes
Add a **Condition** so the flow only continues when it matters. Two common
guards (use either or both):

- **There is an assigned driver:**
  `Assigned Driver Email` **is not equal to** *(empty)*
- **It's a van run, not an outside provider** *(optional — see FACT/Lyft note):*
  `Ride Provider` **is equal to** `None`

> **About "only when status/time changes":** the standard SharePoint trigger
> doesn't natively tell you *which* field changed. Practical options:
> 1. Keep it simple — email on any create/modify of an assigned, van ride
>    (fine for ~10 riders).
> 2. Add a **"Notify driver?" Yes/No column** you tick when you want the email
>    to go out — condition on that, then have the flow untick it. This gives you
>    a manual "send now" switch and avoids accidental re-sends.
> 3. (Advanced) Store a copy of key fields and compare — more work than it's
>    worth at this size.

### Step 3 — Send the email
- **Office 365 Outlook → Send an email (V2)**
- **To:** `Assigned Driver Email`
- **Subject / Body:** from **`email-template.md`** (single-ride version), with the
  list dynamic-content tokens dropped in:
  - Rider, Day, Pickup Time, Pickup Address, Zone, Destination, Return Time,
    Trip Type, Ride Provider, Notes, and `Assigned Driver DisplayName`.

> **FACT / Lyft branch (step G):** if you did NOT filter them out in Step 2, add
> an **If Ride Provider is FACT or Lyft** branch that sends an *awareness-only*
> note ("this rider goes by [provider], no van run needed") instead of a
> drive-this-run email.

### Step 4 (optional) — Post to Teams on changes
- **Microsoft Teams → Post message in a chat or channel** *(standard connector)*
- Team/Channel: your **Senior Transportation** channel
- Message/Card: from **`teams-template.md`** (text or adaptive card).

### Save & test
1. Click **Save**.
2. Click **Test → Manually → run**, then edit a row in the list (e.g., change a
   pickup time) and save. Confirm the email arrives and the Teams post appears.
3. Watch the **flow run history** for any failures (usually a missing field or a
   driver with no email).

---

## Dynamic-content cheat sheet (list field → token)

| Email/Teams placeholder | List dynamic content token |
|---|---|
| Rider | **Rider** (or **Title** if you didn't rename it) |
| Driver's email (To) | **Assigned Driver Email** |
| Driver's name | **Assigned Driver DisplayName** |
| Day | **Day Value** |
| Zone | **Zone Value** |
| Trip type | **Trip Type Value** |
| Pickup time | **Pickup Time** |
| Return time | **Return Time** |
| Pickup address | **Pickup Address** |
| Destination | **Destination** |
| Ride provider | **Ride Provider Value** |
| Notes | **Notes** |

> Choice columns often expose a **`… Value`** token — that's the plain text of
> the choice. Person columns expose **`… Email`** and **`… DisplayName`**.

---

## Design 2 — Weekly digest (sketch)

If you prefer one email per driver per week:

1. **Trigger:** **Recurrence** — e.g., every **Friday 3:00 PM** (for the next
   week) or **Monday 6:00 AM**.
2. **Get items** from **Senior Rides Schedule** (optionally filter to the
   coming week).
3. Build the unique **list of drivers** (an **Apply to each** over the items,
   collecting distinct `Assigned Driver Email`).
4. For each driver: **Filter array** the items to that driver, **Create HTML
   table** of their runs (Day, Pickup Time, Rider, Pickup Address, Zone, Return
   Time, Notes), and **Send an email (V2)** using the *digest* body in
   `email-template.md`.
5. Optional: one **Teams** summary post for the week.

> Design 2 uses only standard connectors too. It's more steps to build but
> sends fewer emails. Build Design 1 first; graduate to this if drivers ask for
> a single weekly email.

---

## Honest caveats

- The standard SharePoint trigger can't tell you *exactly which field* changed —
  use the "Notify driver?" toggle (Step 2) if accidental re-sends bother you.
- If a driver has **no M365 account / no email on file**, the email step will
  fail for that row — that's the case for the Choice-column path; keep the
  name→email map current.
- This flow does **not** plan or optimize routes — it only delivers the
  schedule you built. Route optimization is the separate branch noted in the
  setup guide.
