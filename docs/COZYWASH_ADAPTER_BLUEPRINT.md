# CozyWash adapter blueprint — Phase 6 proposal

**Status: PROPOSED CONTRACT ONLY — not an existing CozyWash API. Owner review and CozyWash-side approval are required before implementation.**

This design preserves CozyWash as an independent, authoritative car-care booking and operations system. GOOBT must not recreate CozyWash bookings, pricing, membership entitlements, capacity, assignments, inspections, payments or service status as a second source of truth.

## Boundary

- GOOBT stores a cross-system reference and minimal handoff lifecycle metadata.
- CozyWash remains authoritative for service catalogue and pricing, customer booking, membership coverage, vehicle eligibility, capacity/slot availability, assigned team, inspection, customer confirmation, washing, quality check, payment, cancellation/refund and completion.
- GOOBT must not write directly to CozyWash tables, use CozyWash service-role credentials from browser code, or import CozyWash's database into GOOBT.
- Customer PII must be minimized; share only the information necessary to request the service and only with clear customer consent.
- A handoff is not a confirmed booking until CozyWash explicitly accepts it and returns its booking reference.
- Do not put CozyWash into the GOOBT main checkout or settlement flow until payment responsibility and merchant-of-record rules are agreed in writing.

## Proposed API surface (versioned)

All routes below are design suggestions, not observed live endpoints.

### Read approved service catalogue
`GET /api/integrations/goobt/v1/services`

Proposed response fields:
- `service_code` — stable CozyWash-owned SKU/service identifier
- `display_name`, `description`
- `currency` (expected ZAR but CozyWash is authoritative)
- `price_minor` or an explicit `quote_required` flag
- `booking_requirements` (minimal structured requirements, e.g. vehicle category)
- `available` (eligibility/discoverability flag, not slot inventory)

Do not copy recurring memberships, employee capacity or dynamic membership-specific prices to GOOBT unless the owner-approved contract expressly permits it.

### Request a service handoff
`POST /api/integrations/goobt/v1/handoffs`

Required headers (proposal):
- `Authorization: Bearer <GOOBT-issued integration credential>` or mTLS; final method to be selected by both owners.
- `Idempotency-Key: <stable GOOBT request key>`
- `X-Contract-Version: 1`

Proposed minimal body:
- `goobt_order_reference` and `goobt_order_item_reference` (opaque, non-PII)
- `service_code`
- `customer`: CozyWash-approved external customer reference if supported; otherwise only consented name/contact fields required for booking
- `vehicle`: only required identifiers/data, such as registration and vehicle category; do not send GOOBT profile data wholesale
- `service_location`: customer-selected location fields required by CozyWash
- `requested_window`: optional preference, not a promise of capacity
- `consent`: explicit service-handoff and cross-system data-sharing confirmation
- `payment_mode`: required only after both sides approve who collects the payment

Proposed response:
- `handoff_id` (opaque integration ID)
- `cozywash_booking_reference` (nullable until accepted)
- `status`: `received | needs_customer_action | accepted | rejected`
- `quote` (optional; CozyWash-authoritative, with expiry)
- `next_action_url` (optional, allow-listed CozyWash origin only)
- `created_at`

### Query handoff state
`GET /api/integrations/goobt/v1/handoffs/{handoff_id}`

Return a minimal status, CozyWash booking reference, quote/payment state if approved, and last-updated timestamp. Avoid returning employee banking, private inspection media, internal notes, or unrelated customer profile data.

### Cancellation request
`POST /api/integrations/goobt/v1/handoffs/{handoff_id}/cancellation`

Cancellation is a request, not a guaranteed reversal. CozyWash applies its own approved booking, payment and refund rules and returns a distinct outcome.

### Signed status webhook
`POST /api/integrations/goobt/v1/events`

Proposed events: `handoff.accepted`, `handoff.rejected`, `booking.status_changed`, `booking.cancelled`, `payment.status_changed` (only if agreed).

Requirements:
- Signed payload with an agreed HMAC or asymmetric signature algorithm and timestamp.
- Reject stale timestamps; persist event ID and enforce idempotency/replay prevention.
- Verify signature before parsing sensitive fields or changing status.
- Retry delivery with exponential backoff; provide an authenticated event replay/reconciliation mechanism.
- Event payload contains opaque GOOBT references and minimum state fields only.

## Status mapping (illustrative; must be approved)

| CozyWash authoritative status | GOOBT adapter display state |
|---|---|
| Handoff received / needs action | Requested |
| Accepted / confirmed booking | Confirmed |
| Assigned | Assigned |
| On the way | En route |
| Arrived | Arrived |
| Inspection / customer confirmation | Inspection |
| Washing | In service |
| Quality check | Quality check |
| Completed | Completed |
| Rejected / cancelled / refunded | Rejected / cancelled / refunded (with source reason code) |

GOOBT may display these states but cannot mutate CozyWash's operational status.

## Security, reliability and contract acceptance checklist
1. CozyWash owner approves endpoint/version, service codes, payload, data minimization and consent wording.
2. Both sides approve authentication, secret rotation, IP/network controls if used, signature algorithm and webhook retries.
3. Define idempotency scope, conflict behavior, rate limits, timeouts and error codes.
4. Define customer identity linking and account deletion/retention handling without creating duplicate identity systems.
5. Define service pricing/quote authority, payment collection, merchant-of-record, settlement, refund/chargeback and cancellation ownership.
6. Define whether handoff creates a booking, a quote request or a customer redirect; never claim a booking is confirmed before CozyWash accepts.
7. Test duplicate requests, replayed/forged webhooks, partial outages, expired quotes, customer cancellation, rejected requests and reconciliation.
8. Review POPIA lawful purpose, minimum necessary sharing, retention, access logging and incident response with the relevant owner/adviser.
9. Provision staging endpoint and test credentials. No production secrets in source control or browser.
10. Keep the adapter feature flag disabled until both sides' contract tests pass and the integration owner approves rollout.

## Current verified state
- GOOBT's `cozywash-handoff` Edge Function authenticates the GOOBT user and deliberately returns 503 `cozywash_adapter_not_configured`.
- A direct read-only inspection of the CozyWash repository found a substantial existing app and its booking/payment Edge Function surface, but no published, owner-approved GOOBT integration endpoint/contract was identified.
- No CozyWash database, app code, credentials, production service, booking or customer record has been changed by this work.
