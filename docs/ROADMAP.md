# GOOBT Delivery Roadmap

## Phase 0 — discovery and architecture
Verified repository, database and Cloudflare starting state. Architecture, entity boundaries, decision log, threat model and release gates documented. Outstanding legal/payment decisions remain explicitly open.

## Phase 1 — platform foundation
Create app shell, environment validation, typed Supabase client, CI, migration discipline, Auth/profile, membership model, RLS and audit baseline. Gate: no cross-tenant reads/writes; no secrets in browser.

## Phase 2 — division storefronts
Division landing pages, catalogue/category/product detail, product media and merchant catalogue operations. No fabricated product content. Gate: published catalogue only, inventory/pricing ownership verified.

## Phase 3 — commerce engine
Cart, server-calculated totals, idempotent checkout, stock reservation, parent order, merchant sub-orders, snapshots, cancellations and partial fulfilment. Gate: concurrency and replay tests pass.

## Phase 4 — payments and fulfilment
Provider-neutral adapter contract, sandbox provider integration, verified webhooks, payment allocation, refunds, reconciliation, shipping/collection methods and notifications. Gate: provider/legal/merchant configuration confirmed; never represent a pending payment as paid.

## Phase 5 — operations and growth
Merchant operations, role-scoped support, promotions, loyalty ledger, analytics, customer communication and operational reporting. Gate: audit trails and tenant isolation validated.

## Phase 6 — CozyWash adapter
Only after CozyWash owner approves API contract, authentication, data-sharing, commercial terms and operational handoff. GOOBT sends a service-order request to CozyWash; CozyWash remains authoritative for bookings, staff, service execution and payment unless a separately approved agreement says otherwise.

## Release stages
Local → CI preview → sandbox integrations → UAT → production. Production deploys require an approved domain, secrets, payment provider, legal documents, merchant onboarding, backups and rollback plan.