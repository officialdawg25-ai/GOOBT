# Integration contracts — fail closed

## Payment adapter
The payment-intent and webhook Edge Function skeletons are stored under `supabase/functions`. They deliberately return 503 until a payment provider, merchant-of-record structure, settlement capability, webhook secret/signature algorithm, idempotency contract, refund protocol and sandbox account are verified. The webhook endpoint has JWT verification disabled for provider callbacks only; it must implement provider signature authentication before being deployed and exposed.

## CozyWash service handoff
The CozyWash handoff function validates GOOBT customer identity but does not call any CozyWash API. It returns a 503 until the owner provides/approves a versioned endpoint, authentication method, payload/response schema, service SKU/pricing authority, consent/data sharing, booking acceptance protocol, cancellation/refund rules and support ownership. CozyWash remains the source of truth.

## Operational constraints
Never send card data to GOOBT. Store provider references, status and amounts only. Verify callback signatures and reconcile provider reports. Never log credentials or full PII payloads.