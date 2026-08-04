# Commission Feature — API & UI Parity (Web → Mobile)

**Source of truth:** web `vcare-agent-app-2.0/src/features/commission/`  
**Mobile:** `lib/features/commission/`  
**Synced to web commit:** see `docs/sync/vcare_last_synced_commit.txt`

---

## Endpoints

| Endpoint | Method | Auth | Query Params |
|---|---|---|---|
| `GET {BASE_URL}api/v1/agents/stats` | GET | Bearer | none |
| `GET {BASE_URL}api/v1/agents/commission-summary` | GET | Bearer | optional `status`, optional `agencyGroupId` |
| `GET {BASE_URL}api/v1/agents/commission-history` | GET | Bearer | `page`, `limit`, optional `status`, optional **`type`** (`all` \| `commission` \| `enrollment` \| `upcoming`), optional `agencyGroupId`, `sortBy=createdAt`, `sortOrder=desc` |
| `GET {BASE_URL}api/v1/agents/sales-history` | GET | Bearer | `page`, `limit` (default **20**), optional `status`, optional `agencyGroupId`, `sortBy=transactionDate`, `sortOrder=desc` |

Responses use the standard envelope:

```json
{ "success": true, "message": "...", "data": {}, "pagination": {} }
```

---

## Agency scoping & list source

`isAgencyTied` (web) / `usesSalesHistory` (mobile) is true when **any** of:

1. Agent stats report `isAgencyAssociated` (`totalCommission === null`)
2. Profile has an agency group (`agencyGroup` / `agencyGroupId` / agency name)
3. Commission summary returns `totalCommission === null`

| Mode | Summary UI | List API (mobile) | List columns | Detail title |
|---|---|---|---|---|
| Independent | Total Sales + Commission + conditional Upcoming / Needs Attention | `commission-history?type=all` | Client · Sale · Commission + status | Commission details |
| Agency-tied | Total Sales + conditional Upcoming / Needs Attention + agency banner | `sales-history` | Client · Sale | Sale details |

**Note:** Web uses `commission-history` for both modes (hides commission column when agency-tied). Mobile keeps `sales-history` for the agency-tied list. Upcoming / Needs Attention aggregates always use `commission-history` with `type` filters (web parity).

When `agencyGroupId` is present on the profile, send it on history / aggregate / sales-history requests. Do **not** send `agencyGroupId` on `commission-summary`.

---

## Summary aggregates (client-side, matches web `useCommissions`)

Base totals come from `GET agents/commission-summary`. Then:

| Metric | Query | Client logic |
|---|---|---|
| Upcoming | `commission-history?type=upcoming&page=1&limit=100` | Sum `salesAmount`, count rows with non-null sales |
| Needs Attention | `commission-history?type=commission&page=1&limit=100` | Keep rows where API status is `FAILED` (`paymentFailed`), then sum `salesAmount` |

Upcoming / Needs Attention cards show when loading **or** count/sales > 0.

Subtext:

- Upcoming: `N scheduled · not counted yet`
- Needs Attention: `N sale(s) that failed to collect`

---

## Screen composition

1. Sticky header: **Sales & Commissions**
2. If summary + aggregates + history are empty → full-page empty state
3. Else:
   - Summary metrics
   - Section title **Your earnings** + entry count
   - List (tap row → detail sheet, or Failed Payment recovery when `paymentFailed`)
   - Prev/Next pager when `total > pageSize`

Status pills **are** shown on list rows (web table chips).

---

## History status labels

| API / context | UI label |
|---|---|
| `FAILED` | Failed |
| `REJECTED` | Rejected |
| `UPCOMING`, or `itemType` `UPCOMING`/`ENROLLMENT`, or id prefix `pending:`/`subscription:` | Upcoming |
| `PENDING` | Pending |
| `PAID` | Successful |

`FAILED` / `UPCOMING` must **not** render as Unknown.

---

## History row fields (commission-history)

| API Field | UI |
|---|---|
| `clientName` / `clientId` | Name (fallback `Client {shortId}`) |
| `clientProfilePreviewLink` | Avatar photo (else initials) |
| `offeringName` | Secondary line under name when present |
| `salesAmount` | Sale |
| `commissionAmount` | Commission (hidden in agency mode) |
| `status` + `type` | Status pill via label mapping above |
| `paidAt` ?? `createdAt` | Date |

### Failed-row recovery

When `status === FAILED` and `clientId` + `transactionId` are present, row tap opens `TodoTransactionDetailSheet` (mobile Failed Payment sheet) instead of the detail drawer. Contact Support from that sheet posts to `POST /contact-support`.

---

## Empty state

- Title: **No sales yet**
- Body (agency): sales will appear when first client is processed
- Body (independent): commissions and sales will appear when first client is processed
- CTA: **View clients** → clients tab

---

## Pagination

Default page size: **20**. Aggregate fetches use limit **100**.

---

## Quick Reference

```
GET  agents/commission-summary
GET  agents/commission-history?page=1&limit=20&type=all&sortBy=createdAt&sortOrder=desc
GET  agents/commission-history?page=1&limit=100&type=upcoming&sortBy=createdAt&sortOrder=desc
GET  agents/commission-history?page=1&limit=100&type=commission&sortBy=createdAt&sortOrder=desc
GET  agents/sales-history?page=1&limit=20&sortBy=transactionDate&sortOrder=desc
POST contact-support   (multipart; failed-payment recovery)
```

All require: `Authorization: Bearer <token>`

**Agency group rule:** `totalCommission === null` (not `0`) drives commission masking.  
**Sale amount on commission-history:** field name is `salesAmount`.
