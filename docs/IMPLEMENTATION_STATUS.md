# GOOBT implementation status — 2026-11-13

## Current delivery state
GOOBT has a committed initial foundation and a Cloudflare Pages development preview. Phase 0 is complete for the initial discovery baseline, including a payment-provider technical evaluation (`PAYMENT_PROVIDER_EVALUATION.md`) with the provider decision still explicitly open. Merchant/customer operations PR #2 has been squash-merged into `main` after CI passed. The product remains **not production-ready and not a fully operational unified marketplace**. External provider/legal/CozyWash prerequisites remain explicit gates.

## Phase ledger
| Phase | Status | Evidence / remaining work |
|---|---|---|
| 0 — Discovery & architecture | VERIFIED / completed for initial baseline | Initial repo, Supabase and Cloudflare audit; architecture, decisions, security, roadmap, integration contracts and release-gate documentation. Legal/payment decisions remain open. |
| 1 — Platform foundation | PARTIAL | React/Vite, Supabase Auth sign-in/sign-up, profile lifecycle, memberships, CI and migrations. 30 public application tables are currently RLS-enabled with 50 policies. Requires first-owner bootstrap, auth redirect setup and live-role RLS tests. |
| 2 — Division storefronts | PARTIAL | Responsive storefront shell, active-division discovery/filtering, live category and text search filters, product detail view with active variant selection, live published catalogue, price display and signed product-media rendering are merged to main. Merchant application, draft product/variant creation with division-scoped active category assignment, strict ZAR minor-unit parsing, collision-resistant slugs, private image upload, merchant image gallery/removal and guarded product publish/pause workflows are merged. A database trigger enforces product/category division consistency. Full category landing/SEO routes, real catalogues, tablet, authenticated-view, keyboard/screen-reader and interaction QA remain. |
| 3 — Commerce engine | PARTIAL / preview groundwork | Customer carts, one-open-cart index, authenticated stock-aware add-to-cart RPC, cart removal, server-calculated checkout preview and order schemas exist. Preview verifies merchant/product status, current price and stock but does not reserve stock, create an order, calculate shipping/tax or accept payment. Transactional order creation, reservations, idempotency, promo/discount computation, cancellation/partial fulfillment and concurrency tests remain. |
| 4 — Payments & fulfilment | BLOCKED / fail-closed skeleton | Payment intent/webhook Edge Function skeletons return 503. Requires provider selection, sandbox credentials, seller-of-record/settlement/legal approval, signed webhooks, reconciliation/refunds, delivery/collection configuration and provider tests. |
| 5 — Operations & growth | PARTIAL / workflow increment | Merged workflows add merchant application review, scoped catalogue drafts, inventory locations/stock adjustment with mandatory reason and movement/audit records, customer address management/order history, customer support intake and audited platform support queue, in-app notifications emitted for support intake/status, merchant application review and merchant entity/settlement review, notification inbox/read state/unread navigation count, live database-backed operations overview, and scoped merchant promotion draft creation with a database activation guard. Promotion redemption and checkout discounts, loyalty earn/redeem workflow, outbound notification delivery, analytics, fulfilment operations and comprehensive role/end-to-end tests remain. |
| 6 — CozyWash adapter | BLOCKED / proposal prepared | A detailed owner-gated API blueprint is documented in `COZYWASH_ADAPTER_BLUEPRINT.md`. The handoff function authenticates GOOBT customer identity and fails closed. No existing CozyWash API contract/credentials were identified; owner approval, CozyWash-side implementation, service pricing/payment authority, consent/data sharing, cancellation and operational support terms remain required. CozyWash remains independent and authoritative. |

## Verified engineering checks
- Customer support intake and platform support case queue were implemented against the live support-case RLS policies and audited `update_support_case` RPC.
- Customer notification inbox/read-state and unread navigation count use customer-owned notification policies; database events emit in-app notifications for support case creation/status changes and merchant application, merchant entity and settlement review outcomes. External email/SMS delivery and user-authored support replies are not implemented.
- Merchant promotion drafts are scoped to the active merchant entity. Draft creation is live; a database trigger blocks activation and enforces merchant/division scope. A direct live-schema negative test rejected an active promotion insert with the expected SQLSTATE; the guard-test row count remained zero. Promotion redemption and checkout discount calculation are intentionally not enabled.
- Shared integer minor-unit commerce helpers are used for UI currency formatting, cart line totals/subtotals and strict ZAR decimal input parsing; unit tests cover arithmetic, overflow, currency, promo draft validation and catalogue filtering.
- Initial foundation PR #1 was squash-merged into `main`.
- Initial foundation GitHub Actions CI passed typecheck, lint, tests and build.
- Cloudflare Pages preview build/deploy completed successfully for the synchronized branch; mobile/desktop screenshot and accessibility-tree checks are partially verified as detailed below.
- Supabase security advisor currently reports zero security lint findings after moving privileged RPC implementations into the private schema behind authenticated invoker wrappers.
- Current direct database counts: 30 public base tables, all 30 with RLS enabled, 50 public RLS policies, 0 Auth users, 0 merchant entities and 0 products. Five business divisions are present and all five are draft; order count remains zero.
- Direct rollback-transaction RLS smoke checks: `anon` saw zero draft divisions, merchant entities and orders; `authenticated` with no JWT subject saw zero merchant entities, orders, support cases and notifications. These baseline checks are not cross-customer or merchant tenant-isolation tests.
- Supabase migration history was reconciled: all 24 remote-applied migration versions now have matching filenames in `supabase/migrations`; no local-only or remote-only migration version remains. This was a repository tree/filename reconciliation, not a database reset.
- The `public.rls_auto_enable()` event-trigger function's execute privileges were directly verified as limited to `postgres` and `service_role`; an idempotent revoke migration is now recorded in the remote migration history.
- Supabase performance advisor currently reports 38 unused-index INFO notices and 14 multiple-permissive-policy WARN notices. With zero real Auth users/orders/catalogue workload, unused-index notices are expected; do not remove indexes or merge policies without workload and tenant-isolation tests.
- Add-to-cart, merchant application/entity/division review, checkout preview and inventory stock adjustment privileged implementations enforce authenticated identity/role and use private schema implementations.
- Latest direct audit: 30 public application tables, all 30 RLS-enabled, 50 policies, and no public table missing a policy.
- The storage bucket for product media is private; storage-object read/write policies scope public reads to active published catalogue media and uploads to merchant/product path ownership.
- Performance advisor still reports unused-index INFO notices in this zero/empty dataset and multiple-permissive-policy WARN notices; these require real workload analysis rather than indiscriminate index/policy removal.
- Cloudflare production deployment remains explicitly disabled.

## Data state at last direct count
- Business divisions: 5 (draft onboarding status)
- Merchant legal entities: 0
- Auth users/profiles: 0
- Products: 0
- Orders: 0
No sample sellers, customer accounts, fake product catalogue, synthetic orders or review/testimonial records were inserted.

## Preview deployment audit
- Cloudflare Pages development project `goobt-commerce-dev` is configured with production deployments disabled; `main` deployments are skipped with reason `production_deployments_disabled`.
- Preview branch allow-list includes `foundation/goobt-full-platform`, `foundation/merchant-operations-console` and `foundation/goobt-preview-current`.
- Current synchronized preview branch deployment `1af0cc4a1ebe7de02d0f9bb9f05826f812cc42cc` completed successfully (clone, build and deploy stages succeeded). Stable branch alias verified from Cloudflare: `https://foundation-goobt-preview-cur.goobt-commerce-dev.pages.dev`.
- A full-page mobile browser render of the current preview at 390 × 844 CSS pixels was visually inspected; header, hero, division tiles, catalogue controls, empty state and footer fit with no visible horizontal overflow. A desktop 1440 × 900 top-viewport screenshot was also inspected; header and hero layout fit cleanly. Accessibility-tree snapshots of the public desktop and mobile landing pages were inspected, including the mobile menu after opening it. Keyboard/screen-reader tests, tablet, authenticated customer/merchant/admin views and full interaction QA remain unverified.
- The latest main CI run should be considered validated only when the run associated with its current commit has completed successfully.

## Release blockers before end-to-end production completion
1. Register and confirm the authorized first platform owner, then perform the controlled grant documented in `OWNER_BOOTSTRAP.md`.
2. Configure Auth Site URL and approved redirect allow-list entries for the preview and development environment.
3. Approve legal merchant entities, seller-of-record roles, VAT/tax/invoicing, consumer terms, privacy, refunds/chargebacks and settlement liability.
4. Select payment provider; verify multi-merchant payment allocation/split-settlement feasibility; supply sandbox credentials and test cases.
5. Define delivery/collection providers, rates, service levels and fulfilment ownership.
6. Add real merchant onboarding and approved catalogue/inventory data; division status activation is an operational/legal decision.
7. Complete RLS tests for anon, customer, merchant roles, platform owner/admin; run checkout concurrency/replay tests and device/browser visual QA.
8. Implement transactional order creation/reservations, provider webhook signature verification, reconciliation, refunds and end-to-end payment state transitions.
9. Complete promotion activation/redemption and checkout discount logic, loyalty earn/redeem rules, outbound email/SMS delivery, support replies/fulfilment operations and end-to-end role tests.
10. Obtain the CozyWash API contract and integration authorization.
11. Approve production domain, monitoring, backups/restore, incident handling and rollback before enabling production deployment.
