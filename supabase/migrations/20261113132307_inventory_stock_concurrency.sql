-- Serialize first-time stock level creation safely when two authorized merchant users adjust same variant/location.
create or replace function private.set_inventory_stock_impl(target_variant_id uuid,target_location_id uuid,desired_on_hand integer,note_text text default null)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
 actor uuid;
 merchant_id uuid;
 level_id uuid;
 current_on_hand integer := 0;
 current_reserved integer := 0;
 delta integer;
begin
 actor:=auth.uid();
 if actor is null then raise exception 'authentication_required' using errcode='42501'; end if;
 if desired_on_hand is null or desired_on_hand<0 then raise exception 'stock_quantity_must_be_nonnegative' using errcode='22023'; end if;
 select p.merchant_entity_id into merchant_id from public.product_variants v join public.products p on p.id=v.product_id where v.id=target_variant_id;
 if merchant_id is null then raise exception 'variant_not_found' using errcode='P0002'; end if;
 if not private.is_merchant_member(merchant_id,array['owner','manager','inventory']) then raise exception 'merchant_inventory_role_required' using errcode='42501'; end if;
 if not exists(select 1 from public.inventory_locations loc where loc.id=target_location_id and loc.merchant_entity_id=merchant_id and loc.status='active') then raise exception 'inventory_location_not_owned_or_inactive' using errcode='42501'; end if;

 select il.id,il.quantity_on_hand,il.quantity_reserved into level_id,current_on_hand,current_reserved
 from public.inventory_levels il where il.variant_id=target_variant_id and il.location_id=target_location_id for update;
 if found then
  if desired_on_hand<current_reserved then raise exception 'stock_cannot_be_less_than_reserved_quantity' using errcode='22023'; end if;
  delta:=desired_on_hand-current_on_hand;
  update public.inventory_levels set quantity_on_hand=desired_on_hand,updated_at=now() where id=level_id;
 else
  insert into public.inventory_levels(variant_id,location_id,quantity_on_hand,quantity_reserved)
  values(target_variant_id,target_location_id,desired_on_hand,0)
  on conflict(variant_id,location_id) do nothing
  returning id into level_id;
  if level_id is not null then
   delta:=desired_on_hand;
   current_on_hand:=0;
   current_reserved:=0;
  else
   select il.id,il.quantity_on_hand,il.quantity_reserved into level_id,current_on_hand,current_reserved
   from public.inventory_levels il where il.variant_id=target_variant_id and il.location_id=target_location_id for update;
   if not found then raise exception 'inventory_level_concurrent_creation_failed' using errcode='P0001'; end if;
   if desired_on_hand<current_reserved then raise exception 'stock_cannot_be_less_than_reserved_quantity' using errcode='22023'; end if;
   delta:=desired_on_hand-current_on_hand;
   update public.inventory_levels set quantity_on_hand=desired_on_hand,updated_at=now() where id=level_id;
  end if;
 end if;
 if delta<>0 then
  insert into public.inventory_movements(inventory_level_id,movement_type,quantity_delta,reference_type,reference_id,actor_user_id,note)
  values(level_id,case when delta>0 then 'receipt' else 'adjustment' end,delta,'stock_adjustment',target_variant_id,actor,nullif(trim(note_text),''));
  insert into public.audit_events(actor_user_id,merchant_entity_id,action,resource_type,resource_id,metadata)
  values(actor,merchant_id,'inventory_stock_adjusted','inventory_level',level_id::text,jsonb_build_object('variant_id',target_variant_id,'location_id',target_location_id,'old_on_hand',current_on_hand,'new_on_hand',desired_on_hand,'delta',delta));
 end if;
 return jsonb_build_object('inventory_level_id',level_id,'quantity_on_hand',desired_on_hand,'quantity_reserved',current_reserved,'delta',delta);
end;
$$;
