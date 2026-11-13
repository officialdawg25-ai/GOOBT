-- GOOBT phase foundation schema. Legal/payment assumptions intentionally not embedded.
create extension if not exists pgcrypto;
create schema if not exists private;

create table public.business_divisions (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
 name text not null,
 description text,
 status text not null default 'draft' check (status in ('draft','active','paused','archived')),
 sort_order int not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table public.merchant_entities (
 id uuid primary key default gen_random_uuid(),
 division_id uuid not null references public.business_divisions(id),
 legal_name text,
 trading_name text not null,
 registration_number text,
 vat_number text,
 country_code char(2) not null default 'ZA',
 status text not null default 'draft' check (status in ('draft','active','paused','archived')),
 merchant_of_record boolean not null default false,
 settlement_status text not null default 'unverified' check (settlement_status in ('unverified','pending_review','approved','suspended')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 phone text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table public.platform_memberships (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check (role in ('platform_owner','platform_admin','platform_operations','platform_support','platform_finance','analyst')),
 created_at timestamptz not null default now(),
 unique(user_id,role)
);

create table public.merchant_memberships (
 id uuid primary key default gen_random_uuid(),
 merchant_entity_id uuid not null references public.merchant_entities(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check (role in ('owner','manager','catalogue','inventory','fulfillment','support','finance','viewer')),
 created_at timestamptz not null default now(),
 unique(merchant_entity_id,user_id)
);

create table public.categories (
 id uuid primary key default gen_random_uuid(),
 division_id uuid not null references public.business_divisions(id),
 parent_id uuid references public.categories(id),
 name text not null,
 slug text not null,
 status text not null default 'draft' check (status in ('draft','active','paused','archived')),
 sort_order int not null default 0,
 unique(division_id,slug)
);

create table public.products (
 id uuid primary key default gen_random_uuid(),
 division_id uuid not null references public.business_divisions(id),
 merchant_entity_id uuid not null references public.merchant_entities(id),
 category_id uuid references public.categories(id),
 name text not null,
 slug text not null,
 description text,
 product_type text not null default 'physical' check (product_type in ('physical','digital','service','made_to_order')),
 status text not null default 'draft' check (status in ('draft','active','paused','archived')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(merchant_entity_id,slug)
);
create index products_public_discovery_idx on public.products(division_id,status,created_at desc);

create table public.product_variants (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 sku text,
 option_values jsonb not null default '{}'::jsonb,
 price_minor bigint not null check (price_minor >= 0),
 currency char(3) not null default 'ZAR',
 status text not null default 'draft' check (status in ('draft','active','paused','archived')),
 created_at timestamptz not null default now(),
 unique(product_id,sku)
);

create table public.product_media (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 storage_path text not null,
 alt_text text,
 sort_order int not null default 0,
 created_at timestamptz not null default now()
);

create table public.inventory_locations (
 id uuid primary key default gen_random_uuid(),
 merchant_entity_id uuid not null references public.merchant_entities(id),
 name text not null,
 location_type text not null default 'warehouse' check (location_type in ('warehouse','store','supplier','virtual')),
 status text not null default 'active' check (status in ('draft','active','paused','archived')),
 created_at timestamptz not null default now()
);

create table public.inventory_levels (
 id uuid primary key default gen_random_uuid(),
 variant_id uuid not null references public.product_variants(id),
 location_id uuid not null references public.inventory_locations(id),
 quantity_on_hand int not null default 0 check (quantity_on_hand >= 0),
 quantity_reserved int not null default 0 check (quantity_reserved >= 0 and quantity_reserved <= quantity_on_hand),
 updated_at timestamptz not null default now(),
 unique(variant_id,location_id)
);

create table public.carts (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'open' check (status in ('open','converted','abandoned')),
 currency char(3) not null default 'ZAR',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index one_open_cart_per_customer on public.carts(customer_id) where status='open';

create table public.cart_items (
 id uuid primary key default gen_random_uuid(),
 cart_id uuid not null references public.carts(id) on delete cascade,
 variant_id uuid not null references public.product_variants(id),
 quantity int not null check (quantity between 1 and 99),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(cart_id,variant_id)
);

create table public.customer_orders (
 id uuid primary key default gen_random_uuid(),
 order_number bigint generated always as identity unique,
 customer_id uuid not null references auth.users(id),
 status text not null default 'pending_payment' check (status in ('pending_payment','paid','processing','partially_fulfilled','fulfilled','cancelled','refunded','partially_refunded')),
 currency char(3) not null default 'ZAR',
 subtotal_minor bigint not null check (subtotal_minor >= 0),
 shipping_minor bigint not null default 0 check (shipping_minor >= 0),
 discount_minor bigint not null default 0 check (discount_minor >= 0),
 total_minor bigint not null check (total_minor >= 0),
 idempotency_key text not null,
 shipping_address jsonb,
 billing_address jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(customer_id,idempotency_key)
);

create table public.merchant_orders (
 id uuid primary key default gen_random_uuid(),
 customer_order_id uuid not null references public.customer_orders(id) on delete cascade,
 merchant_entity_id uuid not null references public.merchant_entities(id),
 status text not null default 'pending_payment' check (status in ('pending_payment','paid','processing','partially_fulfilled','fulfilled','cancelled','refunded','partially_refunded')),
 subtotal_minor bigint not null check (subtotal_minor >= 0),
 shipping_minor bigint not null default 0 check (shipping_minor >= 0),
 total_minor bigint not null check (total_minor >= 0),
 created_at timestamptz not null default now(),
 unique(customer_order_id,merchant_entity_id)
);

create table public.order_items (
 id uuid primary key default gen_random_uuid(),
 merchant_order_id uuid not null references public.merchant_orders(id) on delete cascade,
 product_id uuid not null references public.products(id),
 variant_id uuid not null references public.product_variants(id),
 product_name_snapshot text not null,
 sku_snapshot text,
 quantity int not null check (quantity > 0),
 unit_price_minor bigint not null check (unit_price_minor >= 0),
 line_total_minor bigint not null check (line_total_minor >= 0),
 currency char(3) not null default 'ZAR',
 created_at timestamptz not null default now()
);

create table public.payment_allocations (
 id uuid primary key default gen_random_uuid(),
 customer_order_id uuid not null references public.customer_orders(id),
 merchant_order_id uuid references public.merchant_orders(id),
 provider text not null default 'unconfigured',
 provider_reference text,
 status text not null default 'created' check (status in ('created','pending','authorized','captured','failed','cancelled','refunded','partially_refunded')),
 amount_minor bigint not null check (amount_minor >= 0),
 currency char(3) not null default 'ZAR',
 idempotency_key text not null unique,
 provider_payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table public.fulfillment_groups (
 id uuid primary key default gen_random_uuid(),
 merchant_order_id uuid not null references public.merchant_orders(id) on delete cascade,
 location_id uuid references public.inventory_locations(id),
 status text not null default 'pending' check (status in ('pending','accepted','preparing','ready','dispatched','in_transit','delivered','cancelled','failed')),
 method text not null default 'manual' check (method in ('delivery','collection','digital','service','manual')),
 tracking_reference text,
 recipient_snapshot jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table public.audit_events (
 id uuid primary key default gen_random_uuid(),
 actor_user_id uuid references auth.users(id),
 merchant_entity_id uuid references public.merchant_entities(id),
 action text not null,
 resource_type text not null,
 resource_id text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create table public.integration_connections (
 id uuid primary key default gen_random_uuid(),
 merchant_entity_id uuid references public.merchant_entities(id),
 integration_key text not null,
 status text not null default 'not_configured' check (status in ('not_configured','pending','connected','error','disabled')),
 config_public jsonb not null default '{}'::jsonb,
 secret_reference text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(merchant_entity_id,integration_key)
);

insert into public.business_divisions(slug,name,description,sort_order) values
 ('greylin-harvest','GREYLIN HARVEST','Agriculture and food commerce',10),
 ('oceanbreeze','OCEANBREEZE','Lifestyle and general commerce',20),
 ('opulence-cosmetics','OPULENCE COSMETICS','Cosmetics and skincare',30),
 ('bake-my-day','BAKE MY DAY','Bakery and made-to-order commerce',40),
 ('the-cozywash','THE COZYWASH','Independent mobile car care; adapter integration gated',50);

create or replace function private.is_platform_staff(required_roles text[] default array['platform_owner','platform_admin'])
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.platform_memberships pm
 where pm.user_id=(select auth.uid()) and pm.role=any(required_roles));
$$;
create or replace function private.is_merchant_member(target_merchant uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.merchant_memberships mm
 where mm.user_id=(select auth.uid()) and mm.merchant_entity_id=target_merchant
 and (allowed_roles is null or mm.role=any(allowed_roles)));
$$;
revoke all on function private.is_platform_staff(text[]) from public,anon,authenticated;
revoke all on function private.is_merchant_member(uuid,text[]) from public,anon,authenticated;
grant usage on schema private to authenticated;
grant execute on function private.is_platform_staff(text[]) to authenticated;
grant execute on function private.is_merchant_member(uuid,text[]) to authenticated;

alter table public.business_divisions enable row level security;
alter table public.merchant_entities enable row level security;
alter table public.profiles enable row level security;
alter table public.platform_memberships enable row level security;
alter table public.merchant_memberships enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_media enable row level security;
alter table public.inventory_locations enable row level security;
alter table public.inventory_levels enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.customer_orders enable row level security;
alter table public.merchant_orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payment_allocations enable row level security;
alter table public.fulfillment_groups enable row level security;
alter table public.audit_events enable row level security;
alter table public.integration_connections enable row level security;

create policy divisions_public_read on public.business_divisions for select to anon,authenticated using (status='active');
create policy divisions_platform_manage on public.business_divisions for all to authenticated using (private.is_platform_staff()) with check (private.is_platform_staff());
create policy merchant_entity_member_read on public.merchant_entities for select to authenticated using (private.is_merchant_member(id) or private.is_platform_staff());
create policy merchant_entity_platform_manage on public.merchant_entities for all to authenticated using (private.is_platform_staff()) with check (private.is_platform_staff());
create policy profile_self_select on public.profiles for select to authenticated using (id=(select auth.uid()) or private.is_platform_staff());
create policy profile_self_insert on public.profiles for insert to authenticated with check (id=(select auth.uid()));
create policy profile_self_update on public.profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()));
create policy platform_membership_self_read on public.platform_memberships for select to authenticated using (user_id=(select auth.uid()) or private.is_platform_staff());
create policy platform_membership_owner_manage on public.platform_memberships for all to authenticated using (private.is_platform_staff(array['platform_owner'])) with check (private.is_platform_staff(array['platform_owner']));
create policy merchant_membership_scoped_read on public.merchant_memberships for select to authenticated using (user_id=(select auth.uid()) or private.is_merchant_member(merchant_entity_id,array['owner','manager']) or private.is_platform_staff());
create policy merchant_membership_platform_manage on public.merchant_memberships for all to authenticated using (private.is_platform_staff()) with check (private.is_platform_staff());
create policy categories_public_read on public.categories for select to anon,authenticated using (status='active');
create policy categories_platform_manage on public.categories for all to authenticated using (private.is_platform_staff()) with check (private.is_platform_staff());
create policy products_public_read on public.products for select to anon,authenticated using (
 status='active' and exists(select 1 from public.business_divisions d where d.id=division_id and d.status='active')
 and exists(select 1 from public.merchant_entities m where m.id=merchant_entity_id and m.status='active' and m.settlement_status='approved')
);
create policy products_merchant_manage on public.products for all to authenticated using (
 private.is_merchant_member(merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff()
) with check (private.is_merchant_member(merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff());
create policy variants_public_read on public.product_variants for select to anon,authenticated using (
 status='active' and exists(select 1 from public.products p where p.id=product_id and p.status='active')
);
create policy variants_merchant_manage on public.product_variants for all to authenticated using (
 exists(select 1 from public.products p where p.id=product_id and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff()))
) with check (
 exists(select 1 from public.products p where p.id=product_id and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff()))
);
create policy media_public_read on public.product_media for select to anon,authenticated using (
 exists(select 1 from public.products p where p.id=product_id and p.status='active')
);
create policy media_merchant_manage on public.product_media for all to authenticated using (
 exists(select 1 from public.products p where p.id=product_id and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff()))
) with check (
 exists(select 1 from public.products p where p.id=product_id and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff()))
);
create policy inventory_location_scoped on public.inventory_locations for all to authenticated using (private.is_merchant_member(merchant_entity_id,array['owner','manager','inventory','fulfillment']) or private.is_platform_staff()) with check (private.is_merchant_member(merchant_entity_id,array['owner','manager','inventory','fulfillment']) or private.is_platform_staff());
create policy inventory_levels_scoped on public.inventory_levels for all to authenticated using (
 exists(select 1 from public.inventory_locations l where l.id=location_id and (private.is_merchant_member(l.merchant_entity_id,array['owner','manager','inventory','fulfillment']) or private.is_platform_staff()))
) with check (
 exists(select 1 from public.inventory_locations l where l.id=location_id and (private.is_merchant_member(l.merchant_entity_id,array['owner','manager','inventory','fulfillment']) or private.is_platform_staff()))
);
create policy carts_owner_all on public.carts for all to authenticated using (customer_id=(select auth.uid())) with check (customer_id=(select auth.uid()));
create policy cart_items_owner_all on public.cart_items for all to authenticated using (
 exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=(select auth.uid()))
) with check (
 exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=(select auth.uid()))
);
create policy customer_orders_owner_read on public.customer_orders for select to authenticated using (customer_id=(select auth.uid()) or private.is_platform_staff());
create policy merchant_orders_scoped_read on public.merchant_orders for select to authenticated using (private.is_merchant_member(merchant_entity_id,array['owner','manager','fulfillment','support','finance','viewer']) or private.is_platform_staff() or exists(select 1 from public.customer_orders o where o.id=customer_order_id and o.customer_id=(select auth.uid())));
create policy order_items_scoped_read on public.order_items for select to authenticated using (
 exists(select 1 from public.merchant_orders mo join public.customer_orders co on co.id=mo.customer_order_id
 where mo.id=merchant_order_id and (co.customer_id=(select auth.uid()) or private.is_merchant_member(mo.merchant_entity_id,array['owner','manager','fulfillment','support','finance','viewer']) or private.is_platform_staff()))
);
create policy payment_allocations_owner_read on public.payment_allocations for select to authenticated using (
 exists(select 1 from public.customer_orders o where o.id=customer_order_id and (o.customer_id=(select auth.uid()) or private.is_platform_staff()))
);
create policy fulfillment_groups_scoped_read on public.fulfillment_groups for select to authenticated using (
 exists(select 1 from public.merchant_orders mo join public.customer_orders co on co.id=mo.customer_order_id
 where mo.id=merchant_order_id and (co.customer_id=(select auth.uid()) or private.is_merchant_member(mo.merchant_entity_id,array['owner','manager','fulfillment','support']) or private.is_platform_staff()))
);
create policy audit_platform_read on public.audit_events for select to authenticated using (private.is_platform_staff());
create policy audit_merchant_read on public.audit_events for select to authenticated using (merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager']));
create policy integrations_platform_all on public.integration_connections for all to authenticated using (private.is_platform_staff()) with check (private.is_platform_staff());
create policy integrations_merchant_read on public.integration_connections for select to authenticated using (merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager']));
