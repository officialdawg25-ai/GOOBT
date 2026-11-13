# GOOBT implementation status — 2026-11-13

## Current delivery state
GOOBT has a committed initial foundation and a Cloudflare Pages development preview. Phase 0 is complete for the initial discovery baseline, including a payment-provider technical evaluation (`PAYMENT_PROVIDER_EVALUATION.md`) with the provider decision still explicitly open. Merchant/customer operations PR #2 has been squash-merged into `main` after CI passed. The product remains **not production-ready and not a fully operational unified marketplace**. External provider/legal/CozyWash prerequisites remain explicit gates.

## Phase ledger
| Phase | Status | Evidence / remaining work |
|---|---|---|
| 0 — Discovery & architecture | VERIFIED / completed for initial baseline | Initial repo, Supabase and Cloudflare audit; architecture, decisions, security, roadmap, integration contracts and release-gate documentation. Legal/payment decisions remain open. |
| 1 — Platform foundation | PARTIAL | React/Vite, Supabase Auth sign-in/sign-up, profile lifecycle, memberships, CI and migrations. 30 public application tables are currently RLS-enabled with 50 policies. Requires first-owner bootstrap, auth redirect setup and live-role RLS tests. |
| 2 — Division storefronts | PARTIAL | Responsive storefront shell, active-division discovery/filtering, live category and text search filters, product detail view with active variant selection, live published catalogue, price display and signed product-media rendering are merged to main. Merchant application, draft product/variant creation with division-scoped active category assignment, strict ZAR minor-unit parsing, collision-resistant slugs, private image upload, merchant image gallery/removal and guarded product publish/pause workflows are merged. A database trigger enforces product/category division consistency. Full category landing/SEO routes, real catalogues and visual/device QA remain. |
| 3 — Commerce engine | PARTIAL / preview groundwork | Customer carts, one-open-cart index, authenticated stock-aware add-to-cart RPC, cart removal, server-calculated checkout preview and order schemas exist. Preview verifies merchant/product status, current price and stock but does not reserve stock, create an order, calculate shipping/tax or accept payment. Transactional order creation, reservations, idempotency, promo/discount computation, cancellation/partial fulfillment and concurrency tests remain. |
| 4 — Payments & fulfilment | BLOCKED / fail-closed skeleton | Payment intent/webhook Edge Function skeletons return 503. Requires provider selection, sandbox credentials, seller-of-record/settlement/legal approval, signed webhooks, reconciliation/refunds, delivery/collection configuration and provider tests. |
| 5 — Operations & growth | PARTIAL / workflow increment | Merged workflows add merchant application review, scoped catalogue drafts, inventory locations/stock adjustment with movement/audit records, customer address management/order history, customer support intake and audited platform support queue, in-app notifications emitted for support intake/status, merchant application review and merchant entity/settlement review, notification inbox/read state/unread navigation count, live database-backed operations overview, and scoped merchant promotion draft creation. Promotion activation/redemption and checkout discounts, loyalty earn/redeem workflow, outbound notification delivery, analytics, fulfilment operations and comprehensive role/end-to-end tests remain. |
| 6 — CozyWash adapter | BLOCKED / proposal prepared | A detailed owner-gated API blueprint is documented in `COZYWASH_ADAPTER_BLUEPRINT.md`. The handoff function authenticates GOOBT customer identity and fails closed. No existing CozyWash API contract/credentials were identified; owner approval, CozyWash-side implementation, service pricing/payment authority, consent/data sharing, cancellation and operational support terms remain required. CozyWash remains independent and authoritative. |

## Verified engineering checks
- Customer support intake and platform support case queue were implemented against the live support-case RLS policies and audited `update_support_case` RPC.
- Customer notification inbox/read-state and unread navigation count use customer-owned notification policies; database events emit in-app notifications for support case creation/status changes and merchant application reviews. External email/SMS delivery and user-authored support replies are not implemented.
- Merchant promotion drafts are scoped to the active merchant entity. Draft creation is live; promotion activation, redemption and checkout discount calculation are intentionally not enabled.
- Shared integer minor-unit commerce helpers are used for UI currency formatting, cart line totals/subtotals and strict ZAR decimal input parsing; unit tests cover arithmetic, overflow, currency, promo draft validation and catalogue filtering.
- Initial foundation PR #1 was squash-merged into `main`.
- Initial foundation GitHub Actions CI passed typecheck, lint, tests and build.
- Cloudflare Pages foundation preview deployment completed successfully; external browser inspection was not verified in this audit.
- Supabase security advisor currently reports zero security lint findings after moving privileged RPC implementations into the private schema behind authenticated invoker wrappers.
- Current direct database counts: 30 public base tables, all 30 with RLS enabled, 50 public RLS policies, 0 Auth users, 0 merchant entities and 0 products. Five business divisions are present and all five are draft; order count remains zero.
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
- Preview deployment for the merchant/customer operations branch completed successfully (clone, build and deploy stages succeeded). Preview URL: `https://foundation-merchant-operatio.goobt-commerce-dev.pages.dev`. External visual/browser QA is not verified by this report.
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
9. Complete promotions, loyalty, support/admin operations and notification workflows.
10. Obtain the CozyWash API contract and integration authorization.
11. Approve production domain, monitoring, backups/restore, incident handling and rollback before enabling production deployment.
