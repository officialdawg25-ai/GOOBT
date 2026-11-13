# GOOBT payment-provider evaluation — South Africa

**Status: decision required; no provider is configured or authorized for live payment processing.** This note is technical evaluation only, not legal, tax or regulatory advice.

## GOOBT payment model needs

The intended basket may contain goods/services from more than one division and independent merchant entity. A provider choice must support:
- South African ZAR collections and approved merchant onboarding.
- Multi-recipient allocation or a legally reviewed alternative for each merchant sub-order.
- Refunds, disputes/chargebacks, partial refunds and reconciliation with immutable external references.
- Webhook authenticity verification, replay protection, idempotent payment state transitions.
- Merchant settlement reporting and provider-recipient lifecycle controls.
- Sandbox testability, documentation and clear fee bearer.
- Written provider approval for GOOBT's actual marketplace money flow and merchant-of-record structure.

A gateway that can accept a payment is not automatically a marketplace settlement service. Nor does a payout API itself establish that collecting funds on behalf of multiple independent sellers is permitted.

## Documentation review

### Paystack — technically strongest candidate to investigate for multi-vendor basket settlement
Official docs describe subaccounts, transaction splits and multi-split settlement across the platform payout account plus one or more subaccounts. Multi-split supports dynamic split parameters, multiple recipients, selectable fee-bearer options, and transaction split webhook metadata:
- https://paystack.com/docs/payments/multi-split-payments/
- https://paystack.com/docs/api/split/
- https://paystack.com/docs/api/subaccount/
- https://paystack.com/docs/transfers/

These technical docs do **not** prove that GOOBT will be approved as a marketplace/payment facilitator or that each proposed seller/legal entity is eligible. Confirm with Paystack onboarding and compliance, in writing, before implementation is enabled.

### Payfast — familiar South African integration, but documented split constraint
Payfast's official split-payments documentation describes a split to one receiving merchant per split transaction. That can fit one merchant/provider plus a platform share, but does not by itself establish settlement across several distinct merchants in a single GOOBT basket:
- https://developers.payfast.co.za/
- https://payfast.io/features/split-payments/

A Payfast arrangement could still be assessed for a single-merchant checkout, separate per-merchant payments, or a provider-approved alternate flow. These options alter customer checkout and reconciliation requirements.

### Peach Payments — useful standard collection/payout APIs; marketplace split confirmation needed
Peach documents South African payment collection and payouts. The public material reviewed here does not establish arbitrary multi-recipient marketplace checkout settlement. Obtain written confirmation of recipient/submerchant structure, funds flow, fees, refund ownership, and the account model:
- https://developer.peachpayments.com/docs/reference-reconciliation-settlement-billing
- https://developer.peachpayments.com/docs/pp-payment-methods

## Decision record required before Phase 4 can be enabled

The platform owner and relevant legal/accounting adviser/provider must decide and record:
1. Which legal entity is the customer-facing seller / merchant of record for each division and order.
2. Whether GOOBT will be marketplace facilitator, software marketplace, agent, or another approved arrangement.
3. Provider and account model (platform account, direct merchant accounts, subaccounts, split groups or separate checkout).
4. Provider onboarding and verification obligations for each merchant.
5. Who bears gateway fees, refunds, chargebacks, settlement delays and negative balances.
6. Tax/VAT, invoices, seller receipts and customer cancellation/refund rules.
7. Whether a multi-merchant basket is enabled initially or customer checkout must split into merchant-specific payments.
8. Written provider approval, sandbox credentials and test webhook signing secret.

Until these are settled, the existing payment intent and webhook endpoints intentionally fail closed (503). No secret keys are added to source control or browser configuration, and no payment provider is represented as connected.

## Candidate adapter implementation status (not selected or enabled)

A server-only candidate adapter has been added at `supabase/functions/_shared/payments/paystack.ts`:
- Transaction initialization validates positive integer minor-unit amount, ZAR currency, customer email, reference format, HTTPS callback URL against an explicit origin allow-list, optional payment channels and dynamic split shares.
- It accepts only an HTTPS checkout URL on Paystack's checkout host and checks the provider-returned reference matches the requested reference.
- Webhook verification supports Paystack's current timestamped `Paystack-Signature` header (raw request bytes, 300-second timestamp tolerance, multiple `v1` signatures, secret rotation, constant-time comparison) and the legacy `x-paystack-signature` HMAC mode. An invalid current header never falls back to legacy verification.
- Mocked unit tests are in `src/lib/payments/paystack.test.ts` and `src/lib/payments/paystack-webhook.test.ts`, included in GitHub CI.

**Not wired or enabled:** the candidate is not imported by the `payment-intent` or `payment-webhook` Edge Functions; both remain fail-closed. No Paystack credentials were added and no real provider requests were made. Provider selection, account eligibility, seller-of-record/fund flow, fee bearer policy, merchant subaccount onboarding, order creation, idempotent webhook state transitions, verification/reconciliation and refunds remain required.

Official implementation references:
- [Paystack Transaction API](https://paystack.com/docs/api/transaction/)
- [Paystack Multi-split Payments](https://paystack.com/docs/payments/multi-split-payments/)
- [Paystack Webhooks](https://paystack.com/docs/payments/webhooks/)
