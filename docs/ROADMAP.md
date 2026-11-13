# GOOBT Delivery Roadmap

Phase status is tracked in `docs/IMPLEMENTATION_STATUS.md`. This roadmap defines intended scope and release gates; a phase is not complete merely because part of its UI/schema exists.

## Phase 0 — discovery and architecture
**Status: initial baseline VERIFIED; business/legal decisions still open.** Repository, database and Cloudflare starting state were audited. Architecture, entity boundaries, decision log, threat model, payment provider evaluation, SA compliance readiness checklist, CozyWash adapter proposal and release gates are documented. Remaining seller-of-record, legal merchant, VAT/tax, payment, fulfilment and provider decisions are not inferred.

## Phase 1 — platform foundation
**Status: PARTIAL.** App shell, environment validation, typed Supabase client, CI, migration discipline, Auth/profile, membership model, RLS and audit baseline are present. First platform owner must be registered and email-confirmed, then provisioned by the controlled procedure. Gate: role-matrix and cross-tenant reads/writes verified using real authorized test accounts; no secrets in browser.

## Phase 2 — division storefronts
**Status: PARTIAL.** Responsive division discovery, active division filter, search, live published catalogue, variant pricing and private signed product media display are implemented. Merchant application, draft product/variant creation, product media upload and guarded product publish/pause controls exist. Product category/detail pages, real catalogues, device/browser visual QA and merchant verification evidence remain. No fabricated product content. Gate: published catalogue only; inventory/pricing ownership verified.

## Phase 3 — commerce engine
**Status: PARTIAL / preview only.** Cart, authenticated stock-aware add/remove, integer minor-unit calculations and server-calculated checkout review exist. Checkout preview validates current product/variant/merchant/division eligibility and available stock, but does not create an order, reserve stock, calculate delivery/tax, apply promotions, or process payment. Gate: transactional idempotent order creation, expiring stock reservations, parent order and merchant sub-orders, snapshots, cancellation/partial fulfilment, concurrency/replay/rollback tests and shipping/tax/legal decisions.

## Phase 4 — payments and fulfilment
**Status: BLOCKED / fail-closed skeleton.** Provider-neutral payment intent and webhook endpoints return 503 until provider, seller-of-record/fund-flow approval, credentials, sandbox and signed-webhook contract are established. Payment allocations/order schema exists. Refunds, reconciliation, shipping/collection configuration and end-to-end provider workflow remain. Gate: provider/legal/merchant configuration confirmed; never represent pending payment as paid.

## Phase 5 — operations and growth
**Status: PARTIAL.** Merchant onboarding and audited review, merchant-scoped inventory, stock movements, address management, order-history query, customer support intake and audited platform support queue, notification inbox/read-state and promotion draft creation exist. Promotion redemption/checkout discounts, loyalty earn/redeem ledger workflow, notification delivery providers, analytics, fulfilment operations, support response messaging and end-to-end role testing remain. Gate: audit trails and tenant isolation validated.

## Phase 6 — CozyWash adapter
**Status: BLOCKED / proposal prepared.** Only after CozyWash owner approves API contract, authentication, data-sharing, commercial terms and operational handoff. The owner-gated proposal in `docs/COZYWASH_ADAPTER_BLUEPRINT.md` is not a live API. GOOBT must send a service-order request to CozyWash only after a contract is agreed; CozyWash remains authoritative for bookings, staff, service execution and payment unless a separately approved agreement says otherwise.

## Release stages
Local → CI preview → sandbox integrations → UAT → production. Production deploys require an approved domain, secrets, payment provider, legal documents, merchant onboarding, backups, monitoring and rollback plan. Cloudflare Pages production deployment remains disabled.
