# Architecture Decisions

## Accepted
- Modular monolith before microservices.
- React + TypeScript + Vite PWA.
- Supabase Auth is the single GOOBT identity system.
- PostgreSQL is the system of record for catalogue, inventory, carts, orders and payment allocation metadata.
- ZAR is the initial currency; currency is stored per transaction.
- Brand division and legal merchant entity are separate concepts.
- One customer order may contain multiple merchant sub-orders, but checkout eligibility depends on verified payment/legal design.
- Server-side authorization and row-level security are mandatory.
- No service-role or secret API key in the browser.
- CozyWash remains independent until an adapter is explicitly approved.

## Open — owner/legal/finance decision required
1. Which registered legal entity contracts with each customer and acts as seller-of-record?
2. Is GOOBT principal, marketplace agent, or technology intermediary for each merchant?
3. Which payment provider is selected and does its South African product support lawful multi-party settlement for the intended account structure?
4. Who is responsible for VAT, invoices, refunds, chargebacks and consumer-law obligations?
5. How are commissions, settlement timing, reserves and merchant payouts calculated?
6. Which delivery/collection providers and service-level commitments apply?
7. What are loyalty point issuance, expiry, redemption and liability rules?
8. What privacy notices, retention schedules and operator agreements are approved?
9. What authenticated, versioned CozyWash adapter contract is available?

No unresolved item above is silently assumed by implementation.