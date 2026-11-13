# GOOBT — Unified Commerce Infrastructure

GOOBT is a multi-division, multi-merchant commerce platform. It provides shared customer identity, product discovery, cart and checkout orchestration, payment abstraction, inventory reservations, fulfilment, customer operations and auditability while preserving each division's independent catalogue, pricing, stock, fulfilment and staff permissions.

## Divisions
- GREYLIN HARVEST — agriculture and food
- OCEANBREEZE — lifestyle and general commerce
- OPULENCE COSMETICS — cosmetics and skincare
- BAKE MY DAY — bakery and made-to-order
- THE COZYWASH — independent mobile car care system; adapter integration is gated

Divisions are brand identities, not legal entities. Legal merchant entities, seller-of-record, tax treatment, settlement and commission arrangements must be verified before commercial launch.

## Stack
React + TypeScript + Vite, Supabase Auth/Postgres/Edge Functions/Storage, Cloudflare deployment, GitHub Actions. Initial currency is ZAR. No service-role key belongs in browser code.

## Development
```sh
npm install
npm run dev
npm run typecheck
npm run build
npm run test
```

Copy `.env.example` to `.env.local` and set the Supabase project URL and publishable/anon key. Never commit secrets.

## Delivery status
The repository is being established from an empty starting point. Do not treat it as production-ready until the migration, RLS, checkout, provider sandbox, fulfilment and end-to-end test gates in `docs/RELEASE_GATES.md` pass. No sample products, reviews, sales figures or testimonials are seeded.

## Documentation
See `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/SECURITY.md`, `docs/ROADMAP.md` and `docs/RELEASE_GATES.md`.