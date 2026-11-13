-- Secure customer cart addition. Prices and merchant eligibility are resolved from authoritative rows.
create or replace function public.add_to_cart(target_variant_id uuid, requested_quantity integer default 1)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
 actor uuid;
 cart_id uuid;
 current_quantity integer := 0;
 next_quantity integer;
 p_type text;
 v_price bigint;
 v_currency char(3);
 merchant_ok boolean;
 available_quantity bigint;
 item_id uuid;
begin
 actor := auth.uid();
 if actor is null then raise exception 'authentication_required' using errcode='42501'; end if;
 if requested_quantity is null or requested_quantity<1 or requested_quantity>99 then raise exception 'quantity_must_be_between_1_and_99' using errcode='22023'; end if;

 select p.product_type,v.price_minor,v.currency,
  (p.status='active' and v.status='active' and m.status='active' and m.settlement_status='approved' and d.status='active')
 into p_type,v_price,v_currency,merchant_ok
 from public.product_variants v
 join public.products p on p.id=v.product_id
 join public.merchant_entities m on m.id=p.merchant_entity_id
 join public.business_divisions d on d.id=p.division_id
 where v.id=target_variant_id;
 if not found or merchant_ok is distinct from true then raise exception 'product_not_available' using errcode='P0002'; end if;

 insert into public.carts(customer_id,status,currency) values(actor,'open',v_currency)
 on conflict do nothing returning id into cart_id;
 if cart_id is null then
  select c.id into cart_id from public.carts c where c.customer_id=actor and c.status='open' and c.currency=v_currency order by c.created_at desc limit 1 for update;
 end if;
 if cart_id is null then raise exception 'open_cart_unavailable' using errcode='P0001'; end if;

 select ci.id,ci.quantity into item_id,current_quantity from public.cart_items ci where ci.cart_id=cart_id and ci.variant_id=target_variant_id for update;
 next_quantity := coalesce(current_quantity,0)+requested_quantity;
 if next_quantity>99 then raise exception 'cart_quantity_limit_exceeded' using errcode='22023'; end if;

 if p_type='physical' then
  select coalesce(sum(il.quantity_on_hand-il.quantity_reserved),0) into available_quantity
  from public.inventory_levels il join public.inventory_locations loc on loc.id=il.location_id
  where il.variant_id=target_variant_id and loc.status='active';
  if available_quantity<next_quantity then raise exception 'insufficient_available_stock' using errcode='P0001'; end if;
 end if;

 if item_id is null then
  insert into public.cart_items(cart_id,variant_id,quantity) values(cart_id,target_variant_id,requested_quantity) returning id into item_id;
 else
  update public.cart_items set quantity=next_quantity,updated_at=now() where id=item_id;
 end if;
 return jsonb_build_object('cart_id',cart_id,'cart_item_id',item_id,'quantity',next_quantity,'unit_price_minor',v_price,'currency',v_currency);
end;
$$;
revoke all on function public.add_to_cart(uuid,integer) from public,anon;
grant execute on function public.add_to_cart(uuid,integer) to authenticated;
