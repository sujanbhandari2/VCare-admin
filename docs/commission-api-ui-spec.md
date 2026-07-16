# Commission Feature — API & API-Driven UI

**Document for Web/React implementation parity**

---

## Endpoints

| Endpoint | Method | Auth | Query Params |
|---|---|---|---|
| `GET {BASE_URL}api/v1/agents/commission-summary` | GET | Bearer token | none |
| `GET {BASE_URL}api/v1/agents/commission-history` | GET | Bearer token | `page` (default 1), `limit` (default 20), optional `search` |

Both responses use the standard envelope:

```json
{ "success": true, "message": "...", "data": {}, "pagination": {} }
```

---

## API Fields → UI Behavior

### GET agents/commission-summary

| API Field | UI Element | Behavior |
|---|---|---|
| `totalSales` | Total Sales card | Displayed as currency |
| `totalCommission` | Commission Earned card | Displayed as currency |
| `totalCommission === null` | Agency group mode | Triggers masking across the entire screen |
| `totalCommission === "0"` | Commission Earned card | Shows $0 — individual mode, NOT agency |
| `totalSales === "0"` or null + empty history | Empty state | Shows "No sales yet" screen instead of summary/history |

#### Agency group mode (when `totalCommission === null`)

| UI Element | Behavior |
|---|---|
| Commission Earned card | Shows "XXX" instead of real amount |
| Commission Earned subtitle | Shows "Paid to agency" instead of "This month" |
| Info banner | Shown: "Commissions are paid to your agency and distributed according to your agency's policy." |
| History row title | Masked (not client name) |
| History row amount | Masked (not real amount) |
| History row status badge | Shows "XXX" |
| History row click | Disabled — no detail modal opens |

---

### GET agents/commission-history (each item)

| API Field | UI Element | Behavior |
|---|---|---|
| `clientName` / nested `client.name` / `client.firstName` + `client.lastName` | Row title (client name) | First available value used; fallback to "Client {id}" |
| `commissionAmount` | Row amount | Displayed as signed currency (e.g. +$1.16) |
| `createdAt` | Row date | Formatted as MM/DD/YYYY |
| `status` | Status badge | See status mapping below |
| `status` | Filter chips | Client-side filter only — NOT sent back to API |
| `status` | Detail modal timeline | Different steps shown per status |
| `commissionType` + `commissionValue` | Detail modal — Commission rate | If PERCENTAGE → "5% commission"; otherwise raw value |
| `commissionAmount` | Detail modal — amount | Shown in rate row and commission row |
| `paidAt` | Detail modal timeline — Paid date | Used for "Paid out" step when status is PAID |
| `createdAt` | Detail modal timeline — Processed date | Used for "Processed" step |

#### Example history item payload

```json
{
  "id": "90d500e3-b3bc-4873-9cc2-8e4142650692",
  "clientId": "ca0cf27a-e98c-4d77-b09e-a413c553067f",
  "commissionValue": "5",
  "commissionType": "PERCENTAGE",
  "commissionAmount": "1.16",
  "status": "PENDING",
  "paidAt": null,
  "createdAt": "2026-06-25T12:22:46.546Z"
}
```

---

## Status Mapping (API → UI)

| API `status` value | Badge label | Filter chip match |
|---|---|---|
| `PENDING` | Earned | "Earned" filter |
| `PAID` | Paid | "Paid" filter |
| `CANCELLED` or `CANCELED` | Failed | "Failed" filter |
| anything else | Unknown | none |

---

## Timeline (Detail Modal — driven by `status` + dates)

| API `status` | Timeline steps shown |
|---|---|
| `PENDING` | Processed (date: `createdAt`) → Pending payout |
| `PAID` | Processed (date: `createdAt`) → Paid out (date: `paidAt` or `createdAt`) |
| `CANCELLED` | Processed (date: `createdAt`) → Failed → Paid (pending) |
| unknown | Processed (date: `createdAt`) only |

---

## Pagination (API-driven)

| API field | UI behavior |
|---|---|
| `pagination.total` | Determines if more pages exist |
| `pagination.hasNext` | Triggers load more on scroll near bottom |
| `page` + `limit` query params | Sent on each fetch; page increments on scroll |

Default page size: **20**

---

## What is NOT API-driven (client-side only)

- Filter chips (All / Paid / Earned / Failed) — filters already-fetched data locally
- Agency masking sale titles and amounts — generated client-side in agency group mode
- "This month" label on summary cards — static text
- "No commissions for this filter." message — shown when local filter returns zero items

---

## Quick Reference

```
GET  {BASE_URL}api/v1/agents/commission-summary
GET  {BASE_URL}api/v1/agents/commission-history?page=1&limit=20
```

Both require: `Authorization: Bearer <token>`

**Agency group rule:** `totalCommission === null` (not "0", not missing — explicitly null)

**Status display rule:** API `PENDING` → UI label "Earned"
