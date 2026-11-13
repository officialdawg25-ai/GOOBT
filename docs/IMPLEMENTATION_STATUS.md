# GOOBT implementation status — 2026-11-13

## Current delivery state
GOOBT has a committed initial foundation and a Cloudflare Pages development preview. Phase 0 is complete for the initial discovery baseline. The active merchant/customer workflows are under implementation in PR #2. The product remains **not production-ready and not a fully operational unified marketplace**. External provider/legal/CozyWash prerequisites remain explicit gates.

## Phase ledger
| Phase | Status | Evidence / remaining work |
|---|---|---|
| 0 — Discovery & architecture | VERIFIED / completed for initial baseline | Initial repo, Supabase and Cloudflare audit; architecture, decisions, security, roadmap, integration contracts and release-gate documentation. Legal/payment decisions remain open. |
| 1 — Platform foundation | PARTIAL | React/Vite, Supabase Auth sign-in/sign-up, profile lifecycle, memberships, CI and migrations. 30 public application tables are currently RLS-enabled with 49 policies. Requires first-owner bootstrap, auth redirect setup and live-role RLS tests. |
| 2 — Division storefronts | PARTIAL | Responsive storefront shell, division discovery, search, live published catalogue, price display and signed product-media rendering are implemented in the branch. PR #2 includes merchant application intake, draft product/variant CRUD, gated publish/pause, inventory controls and private media upload. Category/detail pages and visual/device QA remain. Category/detail page and visual/device QA remain. |
| 3 — Commerce engine | PARTIAL / preview groundwork | Customer carts, one-open-cart index, authenticated stock-aware add-to-cart RPC, cart removal, server-calculated checkout preview and order schemas exist. Preview verifies merchant/product status, current price and stock but does not reserve stock, create an order, calculate shipping/tax or accept payment. Transactional order creation, reservations, idempotency, promo/discount computation, cancellation/partial fulfillment and concurrency tests remain. |
| 4 — Payments & fulfilment | BLOCKED / fail-closed skeleton | Payment intent/webhook Edge Function skeletons return 503. Requires provider selection, sandbox credentials, seller-of-record/settlement/legal approval, signed webhooks, reconciliation/refunds, delivery/collection configuration and provider tests. |
| 5 — Operations & growth | PARTIAL / workflow increment | Database structures for promotions, loyalty, support, notifications, addresses, inventory movements and audit are present. PR #2 adds merchant application review, scoped catalogue drafts, inventory locations/stock adjustment with movement/audit records, customer address management, and order-history query. Admin application/merchant/division review, customer address management, product publication, inventory controls and movement audit are in PR #2. Promotions/loyalty/support administration, analytics, fulfillment operations and end-to-end role tests remain. |
| 6 — CozyWash adapter | BLOCKED / contract stub | Handoff function validates GOOBT customer auth and fails closed. Needs CozyWash owner-approved API contract, credentials, pricing authority, consent/data-sharing, cancellation and operational support terms. CozyWash remains independent and authoritative. |

## Verified engineering checks
- Initial foundation PR #1 was squash-merged into `main`.
- Initial foundation GitHub Actions CI passed typecheck, lint, tests and build.
- Cloudflare Pages foundation preview deployment completed successfully; external browser inspection was not verified in this audit.
- Supabase security advisor currently reports zero security lint findings after moving privileged RPC implementations into the private schema behind authenticated invoker wrappers.
- Add-to-cart, merchant application/entity/division review, checkout preview and inventory stock adjustment privileged implementations enforce authenticated identity/role and use private schema implementations.
- Latest direct audit: 30 public application tables, all 30 RLS-enabled, 49 policies, and no public table missing a policy.
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


## Development preview deployment audit — 2026-11-13
- Cloudflare Pages project `goobt-commerce-dev` is configured with production deployments disabled; pushes to `main` are skipped by its production deployment gate.
- Preview branch allow-list includes `foundation/goobt-full-platform` and `foundation/merchant-operations-console`.
- Preview environment contains only the GOOBT Supabase URL and browser publishable key; no service-role key is configured in Vite/browser-facing environment variables.
- A successful CI build does not by itself establish visual/browser QA or authorize production deployment.
