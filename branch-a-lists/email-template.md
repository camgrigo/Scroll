# Email template — "Your rides this week"

This is the body the Power Automate flow sends to each driver. Words in
**[[double brackets]]** are **dynamic content** you insert from the list inside
the flow (Power Automate shows them as clickable tokens). Everything else is
plain typed text.

> Keep the email plain and short — drivers read it on a phone in the van.

---

## Subject

```
Your rides — [[Day]] — Park Avenue Community Center
```

*(If you send a per-driver digest of the whole week instead of one ride at a
time, use: `Your rides this week — Park Avenue Community Center`.)*

---

## Body (single-ride version — fires on each created/changed item)

```
Hi [[Assigned Driver — DisplayName]],

Here is a ride on your list. Please confirm you can cover it.

  Rider:        [[Rider]]
  Day:          [[Day]]
  Pickup:       [[Pickup Time]]  at  [[Pickup Address]]  (Zone [[Zone]])
  Destination:  [[Destination]]
  Return:       [[Return Time]]
  Trip type:    [[Trip Type]]
  Ride provider:[[Ride Provider]]
  Notes:        [[Notes]]

If anything looks wrong, reply to this email or call the center.

— Park Avenue Community Center, Senior Transportation
```

> **FACT / Lyft note:** if **Ride Provider** is **FACT** or **Lyft**, this ride
> is NOT one you drive — it's booked with the outside provider. The flow can add
> a line like: *"This rider is going by [[Ride Provider]] — no van run needed,
> for your awareness only."* (See the condition in `power-automate-flow.md`.)

---

## Body (weekly digest version — one email per driver, all their runs)

Use this if you'd rather send each driver ONE email listing every run. It needs
the "Get items + filter by driver + build an HTML table" steps in
`power-automate-flow.md`.

```
Hi [[Driver name]],

Here are your senior rides for the week of [[week start date]]:

[[HTML table of this driver's runs:
   Day | Pickup Time | Rider | Pickup Address | Zone | Return Time | Notes ]]

Thank you for driving!
— Park Avenue Community Center, Senior Transportation
```
