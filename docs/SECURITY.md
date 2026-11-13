# Security Baseline

- Supabase Auth is the only GOOBT identity provider. Never create parallel customer credentials.
- Use publishable/anon key in the browser only. Service-role and provider secrets stay server-side.
- Enable RLS on every exposed table. Policies must check ownership or merchant/platform membership, not merely authenticated status.
- Authorization uses server-controlled membership records; never trust user-editable auth metadata for roles.
- Privileged SQL functions must use a fixed search_path, minimal grants, explicit identity checks and careful input validation.
- Public catalogue queries return only published products and active divisions.
- Customer addresses, carts, orders, payment details and loyalty balances are private.
- Merchant users can access only records belonging to assigned merchant entities and only within their role.
- Payment callbacks require provider signature verification, idempotency and replay protection.
- Log security-relevant actions without storing card data, secrets or unnecessary PII.
- Rate-limit authentication, checkout, promotion redemption and public endpoints.
- Validate uploads by size, MIME type and ownership; use private buckets for non-public files.
- Use least-privilege GitHub Actions secrets and protected deployment environments.
- Run dependency, type, unit, RLS and end-to-end checks before release.
- Cloudflare account-level 2FA enforcement was observed disabled during initial audit; an account administrator should enable it before production use.
- The existing Supabase RLS event trigger enables RLS on newly created public tables. Preserve and review it; it is not a replacement for policies.