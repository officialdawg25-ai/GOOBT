# GOOBT testing and acceptance plan

## Automated checks currently in CI
GitHub Actions runs:
- `npm run typecheck`
- `npm run lint`
- `npm run test` (Vitest)
- `npm run build`

Unit coverage currently exercises:
- Integer minor-unit cart line/subtotal arithmetic and safe-integer overflow rejection.
- Currency formatting and invalid currency inputs.
- Strict decimal ZAR-to-minor-unit parsing (negative/malformed/excess precision/overflow cases).
- Promotion draft code, discount, usage-limit and date-range validation.
- Catalogue text, division and category filtering.

A passing CI run verifies these automated code checks only. It does not prove that real Auth users, RLS role policies, payment providers, external integrations, production settings, or end-to-end checkout work.

## Preview visual checks
- A mobile full-page browser-rendering screenshot was inspected at 390 × 844 CSS pixels. The landing page, four division tiles, catalogue search/category control, genuine empty-catalogue state and footer fit the mobile layout without visible horizontal overflow.
- This screenshot was captured from the development preview; the current preview branch is synchronized from the latest verified `main` snapshot.
- Desktop 1440px, tablet, accessibility keyboard/screen-reader, auth screens, signed-in customer/merchant/admin views, media gallery interactions and full cross-browser/device visual QA remain to be performed.
- No published product content is present; storefront empty states are expected until real merchant catalogue data is reviewed and published.

## Direct live-schema guard checks (verified; no test rows persisted)
- Attempted to insert a merchant promotion with `status='active'`; the database trigger rejected it with the expected `promotion_activation_not_available_until_checkout_redemption_is_enabled` error. A follow-up count verified zero guard-test rows.
- Attempted to insert a product with a deliberately mismatched/fake category and division; the database trigger rejected it with the expected `product_category_must_be_active_and_belong_to_division` error. A follow-up count verified zero guard-test rows.
- These are targeted negative checks of trigger behavior, not a substitute for role-based RLS or end-to-end staging tests.

## Required role and tenant-isolation UAT (not yet executed)
Use isolated staging/test accounts and a non-production dataset. Do not create fake users or merchants in the current GOOBT project without explicit approval.

| Actor | Allowed examples | Must be denied |
|---|---|---|
| Anonymous visitor | Read active divisions/categories and published products/media | Read draft/unpublished products, private media, customer/cart/order/support data |
| Customer A | Own profile, addresses, cart, order history, notifications, support cases | Customer B data, merchant private operations, platform admin functions |
| Customer B | Own resources only | Customer A resources |
| Merchant owner | Own entity, draft catalogue/media, inventory, merchant-scoped records | Other merchant entity/data, platform review/settlement decisions |
| Merchant manager/catalogue/inventory/support roles | Only role-granted capabilities within assigned merchant entity | Unassigned merchant and restricted platform capabilities |
| Platform support | Platform support queue and approved case operations | Merchant onboarding approval, settlement/division status administration unless separately granted |
| Platform admin/owner | Platform application/entity/division review, audited operations | Unauthorized role escalation, secret access from browser, unapproved settlement/legal decisions |

For every test role, use direct API/RLS negative assertions as well as UI checks; do not rely on hidden navigation.

## Checkout, inventory and payment acceptance (blocked by open decisions)
Before enabling order creation:
- Finalize seller-of-record, tax/VAT, delivery/collection, checkout fee and refund rules.
- Add transactional idempotent order creation, parent/merchant sub-orders, item/price snapshots, stock reservations with expiry/release, and partial cancellation/fulfilment.
- Verify concurrent last-unit purchases, duplicate idempotency keys, rollback on partial failures, stock reservation expiry, stale price/stock rejection, and no oversell.
- Select and approve a provider/account model; test sandbox initialization, signed webhooks, replay rejection, pending/paid/failed/refunded/chargeback states, reconciliation, and provider timeout/retry behavior.
- Ensure browser redirects alone never mark an order paid.

## Support, notifications, merchant onboarding and inventory acceptance
- Customer creates a support case; verify customer-scoped case and automatic in-app notification.
- Platform support changes status/priority/assignee through audited RPC; verify customer notification, audit row and unauthorized role denial.
- Merchant application decision emits a scoped in-app notification; approved entity remains draft/unverified until independent legal/settlement review.
- Merchant entity status/settlement review emits owner notification and audit row.
- Merchant stock adjustment requires reason, writes inventory movement and audit metadata; verify negative quantity and reserved-stock protections.
- Merchant product image upload, signed media display and removal test with private bucket policies; verify cross-merchant path access denied.
- Promotion drafts remain non-redeemable; verify no checkout discount is applied until activation/redemption engine is implemented.

## CozyWash Phase 6 acceptance
Only after the CozyWash owner approves an API contract and staging credentials:
- Contract/schema tests, idempotent handoff, signed webhook verification/replay prevention, status mapping, cancellation/quote expiry, outage/reconciliation and minimal-data/consent tests.
- Verify GOOBT does not mutate CozyWash's source-of-truth booking, price, staff, payment or fulfilment records.

## Release decision
Production release is blocked until all applicable role, checkout, payment, legal, merchant, data privacy, backup/restore, monitoring, rollback, and cross-device acceptance checks have evidence and owner sign-off. Cloudflare production deployments remain disabled.
