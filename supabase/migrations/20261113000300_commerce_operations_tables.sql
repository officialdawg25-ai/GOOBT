-- Phase foundation expansion: promotions, refunds, loyalty, addresses, support, notifications and inventory ledger.
create table public.refunds (
 id uuid primary key default gen_random_uuid(),
 customer_order_id uuid not null references public.customer_orders(id),
 payment_allocation_id uuid references public.payment_allocations(id),
 amount_minor bigint not null check (amount_minor>0),
 currency char(3) not null default 'ZAR',
 status text not null default 'requested' check (status in ('requested','approved','processing','succeeded','failed','rejected')),
 reason text,
 provider_reference text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.fulfillment_items (
 id uuid primary key default gen_random_uuid(),
 fulfillment_group_id uuid not null references public.fulfillment_groups(id) on delete cascade,
 order_item_id uuid not null references public.order_items(id),
 quantity int not null check (quantity>0)
);
create table public.promotions (
 id uuid primary key default gen_random_uuid(),
 division_id uuid references public.business_divisions(id),
 merchant_entity_id uuid references public.merchant_entities(id),
 code text not null unique,
 description text,
 discount_type text not null check (discount_type in ('percentage','fixed')),
 discount_value int not null check (discount_value>0),
 starts_at timestamptz,
 ends_at timestamptz,
 usage_limit int,
 usage_count int not null default 0,
 status text not null default 'draft' check (status in ('draft','active','paused','archived')),
 created_at timestamptz not null default now(),
 check (ends_at is null or starts_at is null or ends_at>starts_at)
);
create table public.loyalty_accounts (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id),
 division_id uuid references public.business_divisions(id),
 points_balance bigint not null default 0 check (points_balance>=0),
 created_at timestamptz not null default now(),
 unique(customer_id,division_id)
);
create table public.loyalty_ledger (
 id uuid primary key default gen_random_uuid(),
 loyalty_account_id uuid not null references public.loyalty_accounts(id),
 points_delta bigint not null check (points_delta<>0),
 reason text not null,
 reference_type text,
 reference_id uuid,
 created_at timestamptz not null default now()
);
create table public.customer_addresses (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id) on delete cascade,
 label text,
 recipient_name text not null,
 phone text,
 address_line1 text not null,
 address_line2 text,
 city text not null,
 province text,
 postal_code text,
 country_code char(2) not null default 'ZA',
 is_default boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index one_default_address_per_customer on public.customer_addresses(customer_id) where is_default;
create table public.customer_notifications (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id) on delete cascade,
 channel text not null default 'in_app' check (channel in ('in_app','email','sms','push')),
 title text not null,
 body text not null,
 resource_type text,
 resource_id text,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create table public.support_cases (
 id uuid primary key default gen_random_uuid(),
 case_number bigint generated always as identity unique,
 customer_id uuid not null references auth.users(id),
 merchant_entity_id uuid references public.merchant_entities(id),
 customer_order_id uuid references public.customer_orders(id),
 subject text not null,
 description text not null,
 status text not null default 'open' check (status in ('open','in_progress','waiting_customer','resolved','closed')),
 priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
 assigned_user_id uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.inventory_movements (
 id uuid primary key default gen_random_uuid(),
 inventory_level_id uuid not null references public.inventory_levels(id),
 movement_type text not null check (movement_type in ('receipt','adjustment','reservation','release','fulfillment','return')),
 quantity_delta int not null check (quantity_delta<>0),
 reference_type text,
 reference_id uuid,
 actor_user_id uuid references auth.users(id),
 note text,
 created_at timestamptz not null default now()
);
alter table public.refunds enable row level security;
alter table public.fulfillment_items enable row level security;
alter table public.promotions enable row level security;
alter table public.loyalty_accounts enable row level security;
alter table public.loyalty_ledger enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.customer_notifications enable row level security;
alter table public.support_cases enable row level security;
alter table public.inventory_movements enable row level security;

create policy refunds_customer_read on public.refunds for select to authenticated using (exists(select 1 from public.customer_orders co where co.id=customer_order_id and (co.customer_id=(select auth.uid()) or private.is_platform_staff())));
create policy refunds_merchant_read on public.refunds for select to authenticated using (payment_allocation_id is not null and exists(select 1 from public.payment_allocations pa join public.merchant_orders mo on mo.id=pa.merchant_order_id where pa.id=payment_allocation_id and private.is_merchant_member(mo.merchant_entity_id,array['owner','manager','finance','support'])));
create policy fulfillment_items_scoped_read on public.fulfillment_items for select to authenticated using (exists(select 1 from public.fulfillment_groups fg join public.merchant_orders mo on mo.id=fg.merchant_order_id join public.customer_orders co on co.id=mo.customer_order_id where fg.id=fulfillment_group_id and (co.customer_id=(select auth.uid()) or private.is_merchant_member(mo.merchant_entity_id,array['owner','manager','fulfillment','support']) or private.is_platform_staff())));
create policy promotions_public_read on public.promotions for select to anon,authenticated using (status='active' and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()));
create policy promotions_merchant_manage on public.promotions for all to authenticated using ((merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager']) or private.is_platform_staff())) with check ((merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager']) or private.is_platform_staff()));
create policy loyalty_accounts_self_read on public.loyalty_accounts for select to authenticated using (customer_id=(select auth.uid()) or private.is_platform_staff());
create policy loyalty_ledger_self_read on public.loyalty_ledger for select to authenticated using (exists(select 1 from public.loyalty_accounts la where la.id=loyalty_account_id and (la.customer_id=(select auth.uid()) or private.is_platform_staff())));
create policy addresses_owner_all on public.customer_addresses for all to authenticated using (customer_id=(select auth.uid())) with check (customer_id=(select auth.uid()));
create policy notifications_owner_all on public.customer_notifications for all to authenticated using (customer_id=(select auth.uid())) with check (customer_id=(select auth.uid()));
create policy support_cases_customer_read on public.support_cases for select to authenticated using (customer_id=(select auth.uid()) or private.is_platform_staff());
create policy support_cases_merchant_read on public.support_cases for select to authenticated using (merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager','support']));
create policy inventory_movements_merchant_read on public.inventory_movements for select to authenticated using (exists(select 1 from public.inventory_levels il join public.inventory_locations loc on loc.id=il.location_id where il.id=inventory_level_id and private.is_merchant_member(loc.merchant_entity_id,array['owner','manager','inventory'])));
