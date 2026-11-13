# GOOBT environment and release configuration

## Supabase browser configuration
The Vite app requires these build-time variables:
- `VITE_SUPABASE_URL=https://tuqnlpoftpjawzxwcmtl.supabase.co`
- `VITE_SUPABASE_ANON_KEY=<project publishable/legacy anon key>`

The publishable/anon key is intentionally browser-facing. Never use a service-role/secret key for Vite variables.

## Cloudflare Pages
Development project: `goobt-commerce-dev`
- Repository: `officialdawg25-ai/GOOBT`
- Build command: `npm run build`
- Output directory: `dist`
- Preview branch allow-list includes `foundation/goobt-full-platform`, `foundation/merchant-operations-console`, and the current synchronized preview branch `foundation/goobt-preview-current`.
- Production deployment is disabled. Main-branch deployment is skipped by configuration.
- Preview deployment hostnames use the `goobt-commerce-dev.pages.dev` domain; deployment-specific URLs and branch aliases should be taken from the Cloudflare Pages deployment record rather than guessed.

Configure the two Vite variables in the Pages **Preview** environment. Production variables and deployment must remain gated until the production release checklist is approved.

## Supabase Auth URL configuration
The current application uses Supabase Auth email confirmation and browser session persistence. The Auth Site URL and redirect allow-list have not been configured through the available project settings connector. Before user acceptance testing:
1. Set the Auth Site URL to the approved preview hostname.
2. Add the exact preview hostname and the local development callback URL used by the team to the Auth Redirect URLs allow-list.
3. Verify confirmation, recovery and sign-in redirects on Android/mobile and desktop.
4. Do not allow broad redirect wildcards unless the security owner has reviewed their scope.

## Release gates
- A custom production domain, legal terms/privacy notices, merchant legal onboarding, payment provider and fulfilment arrangements are still undecided.
- Production Cloudflare deployments must not be enabled merely because CI builds pass.
- Use the Supabase Auth owner bootstrap procedure in `OWNER_BOOTSTRAP.md` after the first authorized owner has registered and confirmed their account.
