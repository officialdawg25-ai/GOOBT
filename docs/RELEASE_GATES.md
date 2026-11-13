# Release Gates and Verification Evidence

Status labels: VERIFIED = directly checked; PARTIAL = some checks pass; INFERRED = reasoned but not tested; PROPOSED = design only; BLOCKED = missing external decision, credential or owner approval.

## Starting-state evidence (2026-11-13)
- VERIFIED: GitHub repository `officialdawg25-ai/GOOBT` existed with only a placeholder README at audit time.
- VERIFIED: Supabase project `tuqnlpoftpjawzxwcmtl` was healthy, PostgreSQL 17, and had no public application tables, migrations, Edge Functions, storage buckets or Auth users at audit time.
- VERIFIED: no GOOBT-specific Cloudflare Pages project or Worker was found in the connected account at audit time.
- VERIFIED: public function `public.rls_auto_enable()` is SECURITY DEFINER and is invoked by the `ensure_rls` DDL event trigger for CREATE TABLE/CTAS/SELECT INTO in public. It enables RLS. Preserve and review; do not remove casually.
- VERIFIED: Cloudflare account-level 2FA enforcement was disabled at audit time.
- VERIFIED: no application or production data was changed during the initial audit.

## Required tests before launch
- Typecheck, lint, unit tests, production build.
- Migration replay from an empty database.
- RLS matrix tests for anonymous, customer A/B, merchant A/B, support and platform admin.
- Cross-tenant object access tests for every table and storage bucket.
- Checkout tests for stale prices, invalid variants, zero stock, concurrent last-unit purchase, idempotent retries, mixed-merchant eligibility and rollback.
- Payment tests for invalid signature, duplicate webhook, out-of-order webhook, timeout, failed capture and refund.
- Fulfilment tests for split shipments, partial delivery and cancellation.
- Mobile viewport, keyboard, accessibility and PWA offline/online checks.
- Backup/restore and deployment rollback rehearsal.

## External blockers
- No payment provider credentials or sandbox account were available in the audited project.
- No merchant legal entity, tax, seller-of-record or settlement model was supplied.
- No merchant product/catalogue/inventory data was supplied.
- No GOOBT-specific Cloudflare Pages/Worker deployment or domain was identified.
- No CozyWash adapter/API contract was supplied.
- No privacy policy, terms, refund policy or merchant agreement was approved.

A repository build is not proof of a commercially launchable marketplace. Mark every release gate with evidence before production.