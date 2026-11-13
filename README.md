# GOOBT — Unified Commerce Infrastructure

GOOBT is a multi-division, multi-merchant commerce platform. It provides shared customer identity, product discovery, cart and checkout orchestration, payment abstraction, inventory reservations, fulfilment, customer operations and auditability while preserving each division's independent catalogue, pricing, stock, fulfilment and staff permissions.

## Divisions
- GREYLIN HARVEST — agriculture and food
- OCEANBREEZE — lifestyle and general commerce
- OPULENCE COSMETICS — cosmetics and skincare
- BAKE MY DAY — bakery and made-to-order
- THE COZYWASH — independent mobile car care system; adapter integration is gated to Phase 6

Divisions are brand identities, not legal entities. Legal merchant entities, seller-of-record, tax treatment, settlement and commission arrangements must be verified before commercial launch.

## Stack
React + TypeScript + Vite, Supabase Auth/Postgres/Edge Functions/Storage, Cloudflare Pages development preview, GitHub Actions. Initial currency is ZAR. No service-role key belongs in browser code.

## Development
```sh
npm install
npm run dev
npm run typecheck
npm run lint
npm run test
npm run build
```

Copy `.env.example` to `.env.local` and set the Supabase project URL and publishable/anon key. Never commit secrets.

## Delivery status
GOOBT has an initial foundation, merchant/customer operations workflows, a development preview and CI. **It is not production-ready and is not yet a complete live marketplace.** Checkout preview is server-calculated but does not create orders or reserve inventory; payment and webhook endpoints fail closed until the provider and marketplace fund flow are approved. An isolated Paystack candidate adapter (initialization and signature-verification code) has CI tests but is not wired or enabled. Promotions are draft-only. Support intake/operations and customer notification inbox/read state are implemented, but outbound notification delivery is not. CozyWash is independent and remains behind an owner-approved API contract.

See `docs/IMPLEMENTATION_STATUS.md` for the phase-by-phase ledger and verified/partial/blocked evidence. No sample products, reviews, sales figures, testimonials, test merchants or customer orders are seeded.

## Documentation
- `docs/ARCHITECTURE.md` — system architecture and boundaries
- `docs/DECISIONS.md` — decisions and open assumptions
- `docs/SECURITY.md` — auth, tenant isolation, RLS and secrets
- `docs/ROADMAP.md` — phases and intended delivery
- `docs/RELEASE_GATES.md` — pre-production verification gates
- `docs/PAYMENT_PROVIDER_EVALUATION.md` — South African provider evaluation and decision requirements
- `docs/COZYWASH_ADAPTER_BLUEPRINT.md` — proposed Phase 6 contract, not a live API
- `docs/OWNER_BOOTSTRAP.md` — controlled first platform-owner provisioning
- `docs/CONFIGURATION.md` — preview environment and Auth redirect configuration
- `docs/SA_COMPLIANCE_READINESS.md` — South African legal, tax, privacy and merchant compliance checklist
- `docs/TESTING.md` — automated coverage and staged role/checkout acceptance plan
