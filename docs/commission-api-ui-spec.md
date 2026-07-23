# Commission Feature — API & API-Driven UI

**Document for Flutter / admin app parity with `GET /api/v1/agents/*` commission endpoints.**

---

## Endpoints

| Endpoint | Method | Auth | Query Params |
|---|---|---|---|
| `GET {BASE_URL}api/v1/agents/stats` | GET | Bearer token | none |
| `GET {BASE_URL}api/v1/agents/commission-summary` | GET | Bearer token | optional `status`, optional `agencyGroupId` |
| `GET {BASE_URL}api/v1/agents/commission-history` | GET | Bearer token | `page` (default 1), `limit` (default 10), optional `status`, optional `agencyGroupId`, `sortBy` (default `createdAt`), `sortOrder` (default `desc`) |
| `GET {BASE_URL}api/v1/agents/sales-history` | GET | Bearer token | `page` (default 1), `limit` (default 10), optional `status`, optional `agencyGroupId`, `sortBy` (default `transactionDate`), `sortOrder` (default `desc`) |

Responses use the standard envelope:

```json
{ "success": true, "message": "...", "data": {}, "pagination": {} }
```

---

## Agency scoping

- When the logged-in profile has an `agencyGroupId`, the app automatically sends it on summary and history requests.
- When `agencyGroupId` is omitted, results are scoped to the caller's agent profile.
- **List source:**
  - Independent agents (no profile `agencyGroupId`) → `commission-history`
  - Agency-associated agents (profile has `agencyGroupId`) → `sales-history`
- Agency **summary/masking** mode in the UI is still driven by the response: `totalCommission === null`.

| Field | Independent agent | Agency-associated / `agencyGroupId` set |
|-------|-------------------|-----------------------------------------|
| `totalSales` | number | number |
| `totalCommission` | number | null |
| `commissionValue` (commission-history) | string | null |
| `commissionAmount` (commission-history / sales-history) | number | null |

`totalSales` and `totalCommission` are **numbers**, not strings.

Commission-history does **not** include transaction/sale amounts. Sale amounts come from sales-history (`amount`).

---

## API Fields → UI Behavior

### GET agents/stats

| API Field | UI Element | Behavior |
|---|---|---|
| `totalClients` | Clients metric | Count |
| `totalSales` | Sales metric | Currency |
| `totalCommission` | Commission metric | Currency when non-null; hidden/placeholder when null |

### GET agents/commission-summary

| API Field | UI Element | Behavior |
|---|---|---|
| `totalSales` | Total Sales card | Displayed as currency |
| `totalCommission` | Commission Earned card | Displayed as currency |
| `totalCommission === null` | Agency group mode | Triggers agency UI across the summary section |
| `totalCommission === 0` | Commission Earned card | Shows $0 — individual mode, NOT agency |
| `totalSales === 0` or null + empty active list | Empty state | Shows "No sales yet" when filter is All |

#### Agency group mode (when `totalCommission === null`)

| UI Element | Behavior |
|---|---|
| Commission Earned card | Shows "XXX" instead of real amount |
| Commission Earned subtitle | Shows "Paid to agency" instead of "This month" |
| Info banner | Shown: commissions are paid to the agency |
| List title | "Total Sales" (sales-history) |
| Sales row amount | Shows sales-history `amount` |
| Sales row status badge | Shows transaction status (`PENDING` / `PAID` / `FAILED` / `REFUNDED` / `VOIDED`) |
| Sales row click | Disabled — no detail modal opens |

---

### GET agents/commission-history (each item) — independent agents

| API Field | UI Element | Behavior |
|---|---|---|
| `clientName` / nested `client` name parts | Row title | First available value; fallback to "Client {id}" |
| `commissionAmount` | Row amount | Signed currency (e.g. +$1.16); null → "—" |
| `createdAt` | Row date | Formatted as MM/DD/YYYY |
| `status` | Status badge / filters | Server-side filter via query param (`PENDING` / `PAID` / `REJECTED`) |
| `commissionType` + `commissionValue` | Detail modal — Commission rate | If PERCENTAGE → "5% commission"; null → "—" |
| `commissionAmount` | Detail modal — amount | Shown when non-null |
| `paidAt` | Detail modal timeline — Paid date | Used for "Paid out" when status is PAID |
| `createdAt` | Detail modal timeline — Processed date | Used for "Processed" |
| `transactionId` | Domain metadata | Linked transaction id (amount not included) |

#### Example commission-history item payload (independent)

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "tenantId": "1f0e8a2b-0000-4000-8000-000000000000",
  "commissionSettingsId": "3c4d5e6f-0000-4000-8000-000000000000",
  "transactionId": "9a8b7c6d-0000-4000-8000-000000000000",
  "agencyGroupId": null,
  "referrerAgentId": "5e6f7a8b-0000-4000-8000-000000000000",
  "clientId": "cccccccc-dddd-eeee-ffff-000000000000",
  "clientName": "Jane Doe",
  "commissionValue": "10",
  "commissionType": "PERCENTAGE",
  "commissionAmount": 50.0,
  "status": "PAID",
  "paidAt": "2026-07-15T10:30:00.000Z",
  "notes": null,
  "createdAt": "2026-07-01T08:00:00.000Z",
  "updatedAt": "2026-07-15T10:30:00.000Z"
}
```

#### Example commission-history item payload (agency-associated)

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "transactionId": "9a8b7c6d-0000-4000-8000-000000000000",
  "agencyGroupId": "ag-1111-2222-3333-4444-555555555555",
  "clientId": "cccccccc-dddd-eeee-ffff-000000000000",
  "clientName": "Acme Corp",
  "commissionValue": null,
  "commissionType": "PERCENTAGE",
  "commissionAmount": null,
  "status": "PENDING",
  "paidAt": null,
  "createdAt": "2026-07-01T08:00:00.000Z"
}
```

---

### GET agents/sales-history (each item) — agency-associated agents

| API Field | UI Element | Behavior |
|---|---|---|
| `payer.name` | Row title | Fallback to "Payer {id}" |
| `amount` | Row amount | Sale currency |
| `transactionDate` | Row date | Formatted as MM/DD/YYYY |
| `status` | Status badge | Transaction status (not commission status) |
| Filter chips | Query `status` | Still uses commission status `PENDING` / `PAID` / `REJECTED` |
| `commissionAmount` | Hidden in agency UI | null for agency-associated agents |

#### Example sales-history item payload

```json
{
  "id": "9a8b7c6d-0000-4000-8000-000000000000",
  "tenantId": "1f0e8a2b-0000-4000-8000-000000000000",
  "payerId": "7c8d9e0f-0000-4000-8000-000000000000",
  "payer": {
    "id": "7c8d9e0f-0000-4000-8000-000000000000",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "phoneNumber": "+15551234567",
    "address": { "line1": "123 Main St", "city": "Austin", "state": "TX", "zip": "78701" },
    "profileId": null,
    "profilePreviewLink": null
  },
  "subscriptionId": "4b5c6d7e-0000-4000-8000-000000000000",
  "paymentMethodId": "2a3b4c5d-0000-4000-8000-000000000000",
  "paymentMethod": {
    "id": "2a3b4c5d-0000-4000-8000-000000000000",
    "type": "card",
    "cardBrand": "visa",
    "cardLast4": "4242",
    "cardExpMonth": 12,
    "cardExpYear": 2028,
    "nickname": null
  },
  "type": "MEMBERSHIP_SUBSCRIPTION",
  "status": "PAID",
  "amount": 500.0,
  "currency": "usd",
  "commissionAmount": null,
  "billingStartDate": "2026-07-01",
  "billingEndDate": "2026-07-31",
  "transactionDate": "2026-07-01T12:00:00.000Z",
  "invoiceNumber": "INV-1001",
  "createdAt": "2026-07-01T12:00:00.000Z",
  "updatedAt": "2026-07-01T12:00:00.000Z"
}
```

---

## Status Mapping (API → UI)

### Commission status (filters + commission-history badges)

| API `status` value | Badge label | Filter chip | Query param |
|---|---|---|---|
| _(none)_ | — | All | omitted |
| `PENDING` | Pending | Pending | `status=PENDING` |
| `PAID` | Paid | Paid | `status=PAID` |
| `REJECTED` | Rejected | Rejected | `status=REJECTED` |

Filter chips refetch summary and the active list with the same commission `status`.

### Transaction status (sales-history badges)

| API `status` value | Badge label |
|---|---|
| `PENDING` | Pending |
| `PAID` | Paid |
| `FAILED` | Failed |
| `REFUNDED` | Refunded |
| `VOIDED` | Voided |

---

## Timeline (Detail Modal — driven by `status` + dates)

Independent commission rows only.

| API `status` | Timeline steps shown |
|---|---|
| `PENDING` | Processed (`createdAt`) → Pending payout |
| `PAID` | Processed (`createdAt`) → Paid out (`paidAt` or `createdAt`) |
| `REJECTED` | Processed (`createdAt`) → Rejected → Paid (pending) |
| unknown | Processed (`createdAt`) only |

---

## Pagination (API-driven)

| API field | UI behavior |
|---|---|
| `pagination.total` | Entry count + whether more pages exist |
| `page` + `limit` query params | Sent on each fetch; page increments on scroll |

Default page size: **10**

- Commission history default sort: `sortBy=createdAt`, `sortOrder=desc`
- Sales history default sort: `sortBy=transactionDate`, `sortOrder=desc`

---

## Quick Reference

```
GET  {BASE_URL}api/v1/agents/stats
GET  {BASE_URL}api/v1/agents/commission-summary?status=PAID&agencyGroupId={id}
GET  {BASE_URL}api/v1/agents/commission-history?page=1&limit=10&status=PAID&sortBy=createdAt&sortOrder=desc
GET  {BASE_URL}api/v1/agents/sales-history?page=1&limit=10&status=PAID&sortBy=transactionDate&sortOrder=desc&agencyGroupId={id}
```

All require: `Authorization: Bearer <token>`

**Agency group rule:** `totalCommission === null` (not `0`, not missing — explicitly null) drives summary masking.

**List source rule:** profile `agencyGroupId` present → sales-history; otherwise → commission-history.

**Profile sync:** commission screen awaits `auth/me` before the first summary/history fetch so `agencyGroupId` is available when present.
