-- Lifecycle triggers: create user profile, maintain updated_at values.
create or replace function private.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path='public','pg_temp'
as $$
begin
 insert into public.profiles(id,display_name)
 values(new.id, coalesce(new.raw_user_meta_data->>'display_name',new.raw_user_meta_data->>'full_name'))
 on conflict(id) do nothing;
 return new;
end;
$$;
revoke all on function private.handle_new_auth_user() from public,anon,authenticated;
drop trigger if exists on_auth_user_created_goobt on auth.users;
create trigger on_auth_user_created_goobt after insert on auth.users
for each row execute function private.handle_new_auth_user();

create or replace function private.set_updated_at()
returns trigger language plpgsql set search_path='pg_catalog'
as $$ begin new.updated_at=now(); return new; end; $$;
revoke all on function private.set_updated_at() from public,anon,authenticated;

do $$
declare t text;
begin
 foreach t in array array[
 'business_divisions','merchant_entities','profiles','products','carts','cart_items',
 'customer_orders','payment_allocations','fulfillment_groups','refunds','customer_addresses',
 'support_cases','integration_connections','inventory_levels'
 ] loop
 execute format('drop trigger if exists set_updated_at_goobt on public.%I',t);
 execute format('create trigger set_updated_at_goobt before update on public.%I for each row execute function private.set_updated_at()',t);
 end loop;
end $$;
