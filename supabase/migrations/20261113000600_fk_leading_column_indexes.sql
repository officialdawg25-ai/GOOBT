-- Leading-column indexes for FK references currently covered only by composite indexes.
create index if not exists idx_cart_items_variant_id on public.cart_items(variant_id);
create index if not exists idx_inventory_levels_location_id on public.inventory_levels(location_id);
create index if not exists idx_loyalty_accounts_division_id on public.loyalty_accounts(division_id);
create index if not exists idx_merchant_memberships_user_id on public.merchant_memberships(user_id);
create index if not exists idx_merchant_orders_merchant_entity_id on public.merchant_orders(merchant_entity_id);
