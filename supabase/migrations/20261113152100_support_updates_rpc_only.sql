-- Force support status/assignment changes through the audited RPC; prevent direct RLS updates from bypassing audit.
drop policy if exists support_cases_platform_update on public.support_cases;
drop policy if exists support_cases_merchant_update on public.support_cases;
