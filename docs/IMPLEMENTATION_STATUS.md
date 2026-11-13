# GOOBT implementation status — 2026-11-13

## Current delivery state
GOOBT is now a committed, deployed development preview and a database-backed foundation. It is **not yet a complete production commerce marketplace**. Phases 0–2 are partial-to-foundation deliverables; phases 3–5 have data-model groundwork but lack complete application workflows; phase 6 is an approved-design gate with only a fail-closed adapter skeleton.

## Phase ledger
| Phase | Status | Evidence / remaining work |
|---|---|---|
| 0 — Discovery & architecture | VERIFIED / completed for initial baseline | Repository, Supabase and Cloudflare audit; architecture, decision, security, roadmap and release-gate docs. Legal/payment decisions remain open. |
| 1 — Platform foundation | PARTIAL | React/Vite app, Supabase Auth sign-in/sign-up, profile trigger, memberships and 29 public DB tables; 29/29 tables RLS enabled, 44 policies. GitHub CI branch build/type/lint/tests passed. Still needs auth redirect configuration and RLS role-matrix test with real roles. |
| 2 — Division storefronts | PARTIAL | Responsive discovery/storefront shell, division brand tiles, search control, live published product query, empty-state handling, Cloudflare Pages preview deployment passed. Merchant catalogue CRUD, category/product detail, product media upload and mobile visual QA remain. |
| 3 — Commerce engine | PROPOSED / schema foundation | Carts, parent customer orders, merchant orders, snapshots, inventory levels and reservation ledger structures exist. Server-side transactional checkout, row-lock reservations, pricing/promo/shipping/tax computation, idempotency, cancellations and partial fulfillment workflows are not yet implemented or tested. |
| 4 — Payments & fulfillment | BLOCKED / skeleton only | Payment intent/webhook Edge Function skeletons fail closed with 503. Requires chosen provider, sandbox credentials, lawful seller-of-record/settlement model, webhook signature verification, reconciliation and provider tests. Fulfillment operations, carrier/collection integrations and customer notifications remain. |
| 5 — Operations & growth | PARTIAL / schema only | Promotions, loyalty, support, addresses, notifications, inventory movement and audit structures exist. Admin/merchant operations interface, analytics, role scoped workflows and tested customer support are unfinished. |
| 6 — CozyWash adapter | BLOCKED / contract stub | Handoff function validates user then returns 503. Requires CozyWash owner-approved versioned API, credentials, payload contract, commercial terms and data-sharing/consent. CozyWash remains independent. |

## Verified engineering checks
- GitHub repository PR #1 was squash-merged to `main`.
- Development branch CI passed typecheck, lint, unit tests and production build.
- Cloudflare Pages preview build and deployment completed successfully for the foundation branch.
- Supabase security advisor: zero security lint findings after revoking direct RPC execution on the existing `public.rls_auto_enable()` event-trigger function.
- Catalog audit: 29 public tables, all 29 have RLS enabled, with 44 policies.
- Performance advisor: no remaining unindexed-FK lint; INFO-level unused-index notices are expected in a new/empty dataset, and WARN-level multiple permissive SELECT policies remain to optimize.
- Production Cloudflare deployment is explicitly disabled; the main-branch Pages deployment was skipped for that reason.

## Release blockers before full end-to-end completion
1. Legal merchant entities and seller-of-record roles per division.
2. VAT/tax/invoicing, consumer terms, privacy and refund/chargeback liability approved.
3. Payment provider selection, split-settlement feasibility, credentials and sandbox test cases.
4. Delivery/collection providers, service levels, rates and fulfillment owner.
5. Merchant onboarding and real product/catalogue/inventory data.
6. RLS test matrix across anonymous, customers, merchant roles and platform staff; checkout concurrency and replay tests.
7. Admin account/role provisioning and operational UI.
8. CozyWash adapter API contract and authorization.
9. Approved production domain, auth redirects, backups/restore, monitoring and rollback.
