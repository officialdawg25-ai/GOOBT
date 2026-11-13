-- Keep SECURITY DEFINER implementations in the non-API private schema; public RPC wrappers are invoker functions.
alter function public.add_to_cart(uuid,integer) set schema private;
alter function private.add_to_cart(uuid,integer) rename to add_to_cart_impl;
revoke all on function private.add_to_cart_impl(uuid,integer) from public,anon;
grant execute on function private.add_to_cart_impl(uuid,integer) to authenticated;
create or replace function public.add_to_cart(target_variant_id uuid, requested_quantity integer default 1)
returns jsonb language sql security invoker set search_path=''
as $$ select private.add_to_cart_impl(target_variant_id,requested_quantity); $$;
revoke all on function public.add_to_cart(uuid,integer) from public,anon;
grant execute on function public.add_to_cart(uuid,integer) to authenticated;

alter function public.review_merchant_application(uuid,text,text) set schema private;
alter function private.review_merchant_application(uuid,text,text) rename to review_merchant_application_impl;
revoke all on function private.review_merchant_application_impl(uuid,text,text) from public,anon;
grant execute on function private.review_merchant_application_impl(uuid,text,text) to authenticated;
create or replace function public.review_merchant_application(application_id uuid, decision text, notes text default null)
returns uuid language sql security invoker set search_path=''
as $$ select private.review_merchant_application_impl(application_id,decision,notes); $$;
revoke all on function public.review_merchant_application(uuid,text,text) from public,anon;
grant execute on function public.review_merchant_application(uuid,text,text) to authenticated;

create index if not exists idx_merchant_applications_division on public.merchant_applications(division_id);
create index if not exists idx_merchant_applications_merchant_entity on public.merchant_applications(merchant_entity_id);
create index if not exists idx_merchant_applications_reviewed_by on public.merchant_applications(reviewed_by);
