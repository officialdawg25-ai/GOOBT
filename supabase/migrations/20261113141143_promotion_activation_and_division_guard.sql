-- Prevent promotion activation until the checkout engine implements server-side discount redemption.
-- Also enforce that merchant-owned promotions stay attached to their merchant's division.
create or replace function private.guard_promotion_activation_and_division_scope()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
 merchant_division_id uuid;
begin
 if NEW.status='active' then
  raise exception 'promotion_activation_not_available_until_checkout_redemption_is_enabled' using errcode='42501';
 end if;
 if NEW.merchant_entity_id is not null then
  select me.division_id into merchant_division_id
  from public.merchant_entities me where me.id=NEW.merchant_entity_id;
  if not found or merchant_division_id is null then
   raise exception 'promotion_merchant_entity_not_found_or_unassigned' using errcode='23503';
  end if;
  if NEW.division_id is distinct from merchant_division_id then
   raise exception 'promotion_division_must_match_merchant_entity' using errcode='23514';
  end if;
 end if;
 return NEW;
end;
$$;
revoke all on function private.guard_promotion_activation_and_division_scope() from public,anon,authenticated;
drop trigger if exists guard_promotion_activation_and_division_scope on public.promotions;
create trigger guard_promotion_activation_and_division_scope
before insert or update of merchant_entity_id,division_id,status on public.promotions
for each row execute function private.guard_promotion_activation_and_division_scope();
