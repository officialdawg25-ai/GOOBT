# GOOBT Architecture

## Product boundary
GOOBT is a shared commerce platform with independent business divisions. A division is a customer-facing brand boundary; a merchant entity is the legal or operational seller account. These are separate records. Never infer legal ownership or merchant-of-record status from a division name.

## Initial architecture
Use a modular monolith. One React PWA consumes Supabase Auth and narrowly exposed data. PostgreSQL owns transactional truth. Edge Functions own privileged orchestration and external provider calls. Cloudflare serves the static app and edge routing. Split services only when measured scale or isolation needs justify it.

## Core modules
1. Identity and customer profile
2. Divisions, merchant entities and role-based access
3. Catalogue, variants, media and category discovery
4. Inventory locations, stock levels and reservations
5. Cart and server-calculated checkout
6. Parent customer order, merchant sub-orders and immutable item snapshots
7. Payment allocations and provider adapters
8. Fulfilment groups, tracking and partial completion
9. Refunds and reconciliation
10. Promotions and loyalty ledger
11. Customer support, notifications and audit events
12. Reporting with tenant-scoped access

## Order model
A customer order is the parent commercial intent. It can contain multiple merchant orders. Merchant orders contain immutable order-item snapshots. Fulfilment groups may split a merchant order by location, delivery method or availability. Payment allocations link provider transactions to parent or merchant orders. A single customer checkout is permitted only when a verified, lawful payment/settlement design exists for every included merchant. Unsupported mixed-merchant carts must be blocked.

## Transaction boundaries
- Server calculates prices, promotions, shipping and tax; browser totals are display-only.
- Checkout uses an idempotency key and a database transaction.
- Lock inventory rows before reserving stock; never permit negative available quantity.
- Persist price/name/SKU/currency snapshots on order items.
- Payment webhooks are signature-verified and idempotent.
- Fulfilment and refunds are merchant/item scoped to support partial outcomes.
- Never mark an order paid based only on a browser redirect.

## CozyWash boundary
The CozyWash application remains authoritative for its own customers, bookings, staff, pricing, payment and fulfilment. GOOBT may later call a versioned adapter for an approved service listing/order handoff. No CozyWash schema, authentication, booking workflow or payment flow is copied or modified by GOOBT.

## Unresolved launch decisions
Seller-of-record; entity ownership/registration; VAT/tax; payment provider and split settlement; commission/fees; shipping contracts and pricing; refund liability; loyalty liability; privacy/retention notices; CozyWash adapter contract. These are release blockers, not defaults to guess.