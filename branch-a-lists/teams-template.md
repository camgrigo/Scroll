# Teams template — schedule-change post

When a ride is **added or changed**, the flow can post a message to a Teams
channel (e.g., a "Senior Transportation" channel) so the team sees updates
without checking email. Two options — pick one.

> **Connector note:** posting **"Post message in a chat or channel"** uses the
> standard **Microsoft Teams** connector — **no premium license needed**.
> Posting a richer **Adaptive Card** also works on the standard connector via
> **"Post adaptive card in a chat or channel"**. Both are fine on normal M365.

---

## Option 1 — Simple text message (easiest)

Action: **Microsoft Teams → Post message in a chat or channel**
- Post as: **Flow bot**
- Post in: **Channel**
- Team / Channel: your **Senior Transportation** team + channel
- Message:

```
🚐 Ride updated
Rider: [[Rider]]  •  Day: [[Day]]  •  Zone: [[Zone]]
Pickup: [[Pickup Time]] at [[Pickup Address]]
Driver: [[Assigned Driver]]  •  Provider: [[Ride Provider]]
Notes: [[Notes]]
```

---

## Option 2 — Adaptive Card (nicer, still standard connector)

Action: **Microsoft Teams → Post adaptive card in a chat or channel**
Paste this JSON into the **Message** (Adaptive Card) box and replace the
`[[...]]` tokens with dynamic content from the list:

```json
{
  "type": "AdaptiveCard",
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "🚐 Senior ride updated",
      "weight": "Bolder",
      "size": "Medium"
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Rider",    "value": "[[Rider]]" },
        { "title": "Day",      "value": "[[Day]]" },
        { "title": "Pickup",   "value": "[[Pickup Time]] — [[Pickup Address]]" },
        { "title": "Zone",     "value": "[[Zone]]" },
        { "title": "Return",   "value": "[[Return Time]]" },
        { "title": "Driver",   "value": "[[Assigned Driver]]" },
        { "title": "Provider", "value": "[[Ride Provider]]" }
      ]
    }
  ]
}
```

> Keep notes/PII to what the channel members are allowed to see — the Teams
> channel is inside your M365 boundary, but still treat addresses/phone numbers
> as need-to-know.
