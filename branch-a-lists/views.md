# Views — how the same list shows different "pages"

A **view** is just a saved way of looking at the *same* list — a different
sort, filter, or layout. You build each one once; after that it's a tab at the
top of your list. **All views read the same data inside your Microsoft 365 — no
copies, nothing leaves the data boundary.**

You'll build four views (this is steps D and G of the plan):

- **(a) Calendar** — see the week's rides on a calendar grid.
- **(b) By Driver** — every run grouped under the driver who's doing it.
- **(c) By Day** — Monday's runs, Tuesday's runs, and so on.
- **(d) FACT / Lyft riders** — only the riders going by an outside provider.

> **Where the view menu is:** at the **top-right of the list**, there's a view
> name (it starts as **"All Items"**) with a small dropdown arrow ⌄. Click it to
> switch views or to **+ Create new view**.

---

## (a) Calendar view

This view is driven by the **Pickup Time** column (a Date and time column — that
date/time is what places each ride on the calendar).

1. List → view dropdown (top-right) → **Create new view**.
2. Name it **Calendar**.
3. Choose **Calendar** as the view type.
4. Set:
   - **Start date** = **Pickup Time**
   - **End date** = **Return Time** *(if a row has no Return Time, it shows as a
     short block; that's fine)*
5. Click **Create**.
6. Open the new **Calendar** view → view dropdown → **Format current view** to
   set the **title** and **subtitle** shown on each calendar block:
   - **Title** = **Rider**
   - **Subtitle** = **Zone** *(or Assigned Driver — pick what helps you most)*
7. Optional: switch the calendar between **Week** and **Month** with the control
   at the top of the calendar.

> **Heads-up:** the sample times all sit on one reference date (a Monday in
> June 2026) just so Lists infers a real Date column. When you enter real rides,
> put each one on its actual date so the calendar spreads across the real week.

---

## (b) "By Driver" grouped view

1. View dropdown → **Create new view** → name **By Driver** → type **List** →
   **Create**.
2. In the new view: view dropdown → **Edit current view** *(or use the column
   header menus)*.
3. **Group by** = **Assigned Driver**.
4. **Sort within group** by **Day**, then **Pickup Time** (ascending).
5. Show columns in this order: Rider, Pickup Address, Day, Pickup Time,
   Return Time, Zone, Ride Provider, Notes.
6. **Save**.

Now each driver's name is a collapsible header with all their runs underneath —
this is what the Power Automate flow mirrors when it emails each driver.

---

## (c) "By Day" grouped view

1. View dropdown → **Create new view** → name **By Day** → type **List** →
   **Create**.
2. **Group by** = **Day**.
3. **Sort within group** by **Zone**, then **Pickup Time** (so geographically
   close riders sit together in time order — an easy starting point for
   routing, same idea as the old Excel tool).
4. Show columns: Rider, Zone, Pickup Time, Trip Type, Pickup Address,
   Assigned Driver, Return Time, Ride Provider, Notes.
5. **Save**.

> **Tip:** Day is text (Mon..Fri), so it groups in alphabetical order
> (Fri, Mon, Thu, Tue, Wed), not weekday order. If that bothers you, rename the
> choices to **1-Mon, 2-Tue, 3-Wed, 4-Thu, 5-Fri** so they sort correctly, or
> just collapse the groups and click the day you want.

---

## (d) "FACT / Lyft riders" filtered view (step G)

Keeps outside-provider riders in the **same list**, just shown on their own tab.

1. View dropdown → **Create new view** → name **FACT / Lyft riders** →
   type **List** → **Create**.
2. **Filter:** show items where **Ride Provider** **is not equal to** **None**.
   *(This shows both FACT and Lyft. To split them, make two views filtered to
   `Ride Provider = FACT` and `Ride Provider = Lyft`.)*
3. **Group by** = **Ride Provider** (so FACT and Lyft are separated).
4. **Sort** by **Day**, then **Pickup Time**.
5. Show columns: Rider, Ride Provider, Day, Pickup Time, Pickup Address,
   Return Time, Notes.
6. **Save**.

---

## Apply the colors (column formatting JSON)

These make the list scannable at a glance. Apply each once:

1. Click the **column header** → **Column settings** → **Format this column**.
2. Click **Advanced mode**.
3. Open the matching `.json` file from the `column-formatting/` folder, copy
   **all** of it, paste it in, and click **Save**.

| Column | JSON file | What you'll see |
|---|---|---|
| **Zone** | `column-formatting/zone-color.json` | N = blue, E = green, S = gold, W = orange pills |
| **Ride Provider** | `column-formatting/ride-provider-color.json` | FACT = orange, Lyft = purple, None = grey |
| **Trip Type** | `column-formatting/trip-type-color.json` | Round trip = blue, Pickup only = green, Return only = orange |

Colors apply across **all** views automatically once set on the column.

---

## Color key (matches the JSON above)

| Color | Means |
|---|---|
| 🔵 Blue | Zone **N** / Round trip |
| 🟢 Green | Zone **E** / Pickup only |
| 🟡 Gold | Zone **S** |
| 🟠 Orange | Zone **W** / Return only / **FACT** |
| 🟣 Purple | **Lyft** |
| ⚪ Grey | Ride Provider **None** (your own vans) |
