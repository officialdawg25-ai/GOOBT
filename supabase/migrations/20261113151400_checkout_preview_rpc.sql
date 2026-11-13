-- Authoritative cart review: server-calculated prices and stock checks without creating orders or reserving inventory.
create or replace function private.checkout_preview_impl()
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
 actor uuid;
 cart_id uuid;
 row_item record;
 line_total bigint;
 subtotal bigint := 0;
 merchant_ids uuid[] := array[]::uuid[];
 items jsonb := '[]'::jsonb;
 available_quantity bigint;
begin
 actor := auth.uid();
 if actor is null then raise exception 'authentication_required' using errcode='42501'; end if;
 select c.id into cart_id from public.carts c where c.customer_id=actor and c.status='open' and c.currency='ZAR' order by c.created_at desc limit 1 for update;
 if cart_id is null then raise exception 'cart_empty' using errcode='P0002'; end if;

 for row_item in
  select ci.id as cart_item_id,ci.quantity,v.id as variant_id,v.price_minor,v.currency,v.status as variant_status,
   p.id as product_id,p.name as product_name,p.product_type,p.status as product_status,p.merchant_entity_id,
   m.trading_name as merchant_name,m.status as merchant_status,m.settlement_status,d.status as division_status
  from public.cart_items ci
  join public.product_variants v on v.id=ci.variant_id
  join public.products p on p.id=v.product_id
  join public.merchant_entities m on m.id=p.merchant_entity_id
  join public.business_divisions d on d.id=p.division_id
  where ci.cart_id=cart_id
  order by ci.created_at,ci.id
 loop
  if row_item.product_status<>'active' or row_item.variant_status<>'active' or row_item.merchant_status<>'active' or row_item.settlement_status<>'approved' or row_item.division_status<>'active' then
   raise exception 'cart_contains_unavailable_item' using errcode='P0001';
  end if;
  if row_item.currency<>'ZAR' then raise exception 'mixed_or_unsupported_currency' using errcode='22023'; end if;
  if row_item.product_type='physical' then
   select coalesce(sum(il.quantity_on_hand-il.quantity_reserved),0) into available_quantity
   from public.inventory_levels il join public.inventory_locations loc on loc.id=il.location_id
   where il.variant_id=row_item.variant_id and loc.status='active';
   if available_quantity<row_item.quantity then raise exception 'insufficient_available_stock' using errcode='P0001'; end if;
  end if;
  line_total := row_item.price_minor*row_item.quantity;
  subtotal := subtotal+line_total;
  if not row_item.merchant_entity_id=any(merchant_ids) then merchant_ids:=array_append(merchant_ids,row_item.merchant_entity_id); end if;
  items := items || jsonb_build_array(jsonb_build_object(
   'cart_item_id',row_item.cart_item_id,'product_id',row_item.product_id,'product_name',row_item.product_name,
   'product_type',row_item.product_type,'merchant_entity_id',row_item.merchant_entity_id,'merchant_name',row_item.merchant_name,
   'quantity',row_item.quantity,'unit_price_minor',row_item.price_minor,'line_total_minor',line_total,'currency',row_item.currency
  ));
 end loop;
 if jsonb_array_length(items)=0 then raise exception 'cart_empty' using errcode='P0002'; end if;
 return jsonb_build_object('cart_id',cart_id,'currency','ZAR','subtotal_minor',subtotal,'merchant_count',cardinality(merchant_ids),'items',items,'shipping_calculated',false,'tax_calculated',false,'inventory_reserved',false,'payment_ready',false);
end;
$$;
revoke all on function private.checkout_preview_impl() from public,anon;
grant execute on function private.checkout_preview_impl() to authenticated;
create or replace function public.checkout_preview()
returns jsonb language sql security invoker set search_path=''
as $$ select private.checkout_preview_impl(); $$;
revoke all on function public.checkout_preview() from public,anon;
grant execute on function public.checkout_preview() to authenticated;
