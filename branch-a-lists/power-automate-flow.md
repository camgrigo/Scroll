# Power Automate flow — per-driver Outlook emails (step E)

**Goal:** replace "print the schedule and hand it out" with one weekly flow that
emails **each person only what they need**:

| Recipient (role) | Gets |
|---|---|
| **Driver 1** | Only Driver 1's own van runs for the week |
| **Driver 2** | Only Driver 2's own van runs for the week |
| **FACT Coordinator** | The full **FACT / Lyft** list (the outside-provider riders) |
| **Supervisor** | The full weekly summary (every ride) |

The two drivers never get the FACT/Lyft riders, and the FACT Coordinator handles
those separately — exactly the split the team uses today.

**Stays in the boundary:** Power Automate, Lists/SharePoint, and Outlook are all
Microsoft 365. No rider data leaves your tenant. **No outside AI is involved.**

**Connector cost:** everything uses **standard** connectors (SharePoint/Lists,
Office 365 Outlook). **No premium license required.**

---

## Before you build: the role → email map

"Assigned Driver" is a **Choice** of four roles (placeholder names), not real
accounts — so the flow needs to know each role's real email address. You set this
once, at the top of the flow, with an **Initialize variable** (type **Object**):

```
roleEmails  =
{
  "Driver 1":         "driver1@yourorg.org",
  "Driver 2":         "driver2@yourorg.org",
  "FACT Coordinator": "factcoord@yourorg.org",
  "Supervisor":       "supervisor@yourorg.org"
}
```

To get one address in a later step, use:
`variables('roleEmails')?['Driver 1']` (or build the key from a list field).
Keep this map current and you never touch the rest of the flow when people change.

---

## Primary design — weekly per-driver digest (build this one)

A single scheduled flow that sends the four emails above. Steps:

### Trigger
- **Recurrence** — e.g. every **Friday 3:00 PM** (for the coming week), or
  **Monday 6:00 AM**. Pick the time you'd normally hand out the schedule.

### Step 0 — Initialize the role→email map
- **Initialize variable** → Name `roleEmails`, Type **Object**, Value = the JSON
  block above.

### Step 1 — Get the week's rides
- **SharePoint → Get items**
  - **Site Address:** the site holding your list
  - **List Name:** **Senior Rides Schedule**
  - *(Optional **Filter Query** to limit to the coming week once you enter real
    dates, e.g. `PickupTime ge '2026-06-15'`.)*

### Step 2 — Email each van driver their own runs
Do this **once for Driver 1** and **once for Driver 2** (two parallel branches,
identical except the role name):

1. **Filter array** on the Get items output:
   - `Assigned Driver Value` **is equal to** `Driver 1`, **and**
   - `Outside Ride (FACT/Lyft) Value` **is equal to** `No`
2. **Create HTML table** from the filtered array — columns: Day, Pickup Time,
   Rider, Pickup Address, Zone, Return Time, Notes.
3. **Office 365 Outlook → Send an email (V2)**
   - **To:** `variables('roleEmails')?['Driver 1']`
   - **Subject / Body:** the **driver digest** body in `email-template.md`,
     with the HTML table dropped in.

> Because Step 1 of the filter is the role name and Step 2 excludes
> `Outside Ride = Yes`, each driver gets **only their own van runs** and never
> the FACT/Lyft riders.

### Step 3 — Email the FACT Coordinator the outside-provider list
1. **Filter array:** `Outside Ride (FACT/Lyft) Value` **is equal to** `Yes`.
2. **Create HTML table** — columns: Day, Pickup Time, Rider, Pickup Address,
   Return Time, Notes (note says FACT or Lyft).
3. **Send an email (V2)**
   - **To:** `variables('roleEmails')?['FACT Coordinator']`
   - **Body:** the **FACT/Lyft list** body in `email-template.md`.

### Step 4 — Email the Supervisor the full weekly summary
1. **Create HTML table** from the **full** Get items output (no filter) —
   columns: Day, Pickup Time, Rider, Zone, Assigned Driver, Outside Ride, Notes.
2. **Send an email (V2)**
   - **To:** `variables('roleEmails')?['Supervisor']`
   - **Body:** the **supervisor summary** body in `email-template.md`.

### Save & test
1. **Save** → **Test → Manually → run**.
2. Confirm four emails arrive: Driver 1 (their runs only), Driver 2 (their runs
   only), FACT Coordinator (FACT/Lyft list), Supervisor (everything).
3. Check **flow run history** for any failures (usually a wrong address in the
   role map or an empty filter).

---

## Dynamic-content cheat sheet (list field → token)

| Placeholder | List dynamic content token |
|---|---|
| Rider | **Rider** (or **Title** if you didn't rename it) |
| Assigned role | **Assigned Driver Value** |
| Outside-ride flag | **Outside Ride (FACT/Lyft) Value** (`Yes`/`No`) |
| Day | **Day Value** |
| Zone | **Zone Value** |
| Trip type | **Trip Type Value** |
| Pickup time | **Pickup Time** |
| Return time | **Return Time** |
| Pickup address | **Pickup Address** |
| Destination | **Destination** |
| Notes | **Notes** |

> Choice columns expose a **`… Value`** token — the plain text of the choice.
> A Yes/No column returns `true`/`false` in conditions but shows as `Yes`/`No`.

---

## Optional add-on — mid-week change alert

If you change a ride mid-week and want the affected driver to know right away,
add a **second, separate** flow:

1. **Trigger:** **SharePoint → When an item is created or modified**, List =
   **Senior Rides Schedule**.
2. **Condition:** `Outside Ride (FACT/Lyft) Value` **is equal to** `No`
   *(skip outside-provider rows — those go to the FACT Coordinator)*.
3. **Get the email:** `variables('roleEmails')?[ <Assigned Driver Value> ]`
   (initialize the same role map at the top).
4. **Send an email (V2)** to that driver using the single-ride body in
   `email-template.md`.

> The standard SharePoint trigger can't tell you *which* field changed, so this
> fires on any save of a van row. Add a **"Notify driver?" Yes/No column** you
> tick when you want the alert, then have the flow untick it, if accidental
> re-sends bother you.

---

## Optional — Teams post

Posting to a Teams channel is **demoted to optional** (the team asked for email).
If you still want a channel post on changes, `teams-template.md` has a standard
**Microsoft Teams → Post message in a chat or channel** action you can add as an
extra step. No premium license needed.

---

## Honest caveats

- Keep the **role → email map** current — a wrong address is the most common
  failure.
- This flow **delivers** the schedule you built; it does **not** plan or optimize
  routes. Route optimization is the separate branch noted in the setup guide.
