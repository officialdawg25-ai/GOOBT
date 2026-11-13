-- Hardening follow-up: retain event trigger while removing public RPC execution exposure.
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
