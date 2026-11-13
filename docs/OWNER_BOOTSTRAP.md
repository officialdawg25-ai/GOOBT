# GOOBT first-owner bootstrap

The platform does not seed an administrator, create a test account, or grant elevated privileges during public signup.

## Controlled one-time procedure
1. Confirm the intended first platform owner is the person authorized to administer GOOBT.
2. Register that person's account through the GOOBT sign-up screen and complete the Supabase email confirmation.
3. In the Supabase SQL Editor for project `tuqnlpoftpjawzxwcmtl`, run the following statement after replacing `OWNER_EMAIL` with the exact confirmed account email (lowercase). Do not run it before the account exists.

```sql
insert into public.platform_memberships(user_id,role)
select id,'platform_owner'
from auth.users
where lower(email)=lower('OWNER_EMAIL')
on conflict(user_id,role) do nothing;
```

4. Verify the grant:

```sql
select u.email,pm.role,pm.created_at
from auth.users u
join public.platform_memberships pm on pm.user_id=u.id
where lower(u.email)=lower('OWNER_EMAIL');
```

5. Sign out and sign in again so the frontend refreshes the role query. The Operations navigation becomes available to the platform owner.

## Security notes
- Do not grant platform_owner to an unverified or shared inbox.
- Do not add a role-grant endpoint to the public application.
- Do not place the Supabase service-role key in Cloudflare Pages environment variables exposed to Vite/browser code.
- Platform memberships are managed by platform owner privileges. Merchant applicants cannot self-approve or create their own merchant entity.
- If the email query returns zero rows, stop and check the Auth user email rather than manually guessing a UUID.
