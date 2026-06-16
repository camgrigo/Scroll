# Email templates — per-driver Outlook emails

These are the bodies the **primary** Power Automate flow sends. Each recipient
gets only what they need (see `power-automate-flow.md`). Words in
**[[double brackets]]** are **dynamic content** you insert from the list inside
the flow; everything else is plain typed text.

> Keep emails plain and short — drivers read them on a phone in the van.

---

## 1. Driver digest — "Your rides this week" (Driver 1 / Driver 2)

One email per driver, listing **only their own van runs**.

**Subject**

```
Your rides this week — Park Avenue Community Center
```

**Body**

```
Hi [[Driver 1 / Driver 2]],

Here are your senior van rides for the coming week:

[[HTML table of this driver's runs:
   Day | Pickup Time | Rider | Pickup Address | Zone | Return Time | Notes ]]

These are van runs only — FACT/Lyft riders are handled by the coordinator.
If anything looks wrong, reply to this email or call the center.

Thank you for driving!
— Park Avenue Community Center, Senior Transportation
```

---

## 2. FACT Coordinator — "FACT / Lyft riders this week"

One email listing every rider flagged **Outside Ride = Yes**.

**Subject**

```
FACT / Lyft riders this week — Park Avenue Community Center
```

**Body**

```
Hi [[FACT Coordinator]],

Here are the riders going by an outside provider (FACT or Lyft) this week —
please confirm their bookings:

[[HTML table of Outside Ride = Yes rows:
   Day | Pickup Time | Rider | Pickup Address | Return Time | Notes (FACT/Lyft) ]]

These riders are not on a van run.
— Park Avenue Community Center, Senior Transportation
```

---

## 3. Supervisor — "Full weekly schedule"

One email with every ride for oversight.

**Subject**

```
Weekly senior rides summary — Park Avenue Community Center
```

**Body**

```
Hi [[Supervisor]],

Here is the full senior rides schedule for the coming week:

[[HTML table of ALL rows:
   Day | Pickup Time | Rider | Zone | Assigned Driver | Outside Ride | Notes ]]

— Park Avenue Community Center, Senior Transportation
```

---

## 4. Single-ride body (optional mid-week change alert)

Used by the optional second flow that fires when one van ride changes
(see `power-automate-flow.md` → "mid-week change alert").

```
Hi [[Assigned Driver]],

Heads up — this ride on your list changed. Please confirm you can cover it.

  Rider:        [[Rider]]
  Day:          [[Day]]
  Pickup:       [[Pickup Time]]  at  [[Pickup Address]]  (Zone [[Zone]])
  Destination:  [[Destination]]
  Return:       [[Return Time]]
  Trip type:    [[Trip Type]]
  Notes:        [[Notes]]

If anything looks wrong, reply to this email or call the center.
— Park Avenue Community Center, Senior Transportation
```
