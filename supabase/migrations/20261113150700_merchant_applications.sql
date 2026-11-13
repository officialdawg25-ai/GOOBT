-- Merchant applications: allow authenticated prospective sellers to request onboarding.
create table public.merchant_applications (
 id uuid primary key default gen_random_uuid(),
 applicant_user_id uuid not null references auth.users(id) on delete cascade,
 division_id uuid not null references public.business_divisions(id),
 legal_name text not null,
 trading_name text not null,
 registration_number text,
 vat_number text,
 contact_email text not null,
 contact_phone text,
 business_summary text not null,
 country_code char(2) not null default 'ZA',
 status text not null default 'submitted' check (status in ('submitted','under_review','needs_information','approved','rejected','withdrawn')),
 review_notes text,
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 merchant_entity_id uuid references public.merchant_entities(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check (status<>'approved' or merchant_entity_id is not null)
);
create index idx_merchant_applications_applicant on public.merchant_applications(applicant_user_id);
create index idx_merchant_applications_status_created on public.merchant_applications(status,created_at);
alter table public.merchant_applications enable row level security;
create policy merchant_application_owner_read on public.merchant_applications for select to authenticated using (applicant_user_id=(select auth.uid()));
create policy merchant_application_owner_insert on public.merchant_applications for insert to authenticated with check (applicant_user_id=(select auth.uid()) and status='submitted' and reviewed_by is null and reviewed_at is null and merchant_entity_id is null);
create policy merchant_application_platform_read on public.merchant_applications for select to authenticated using (private.is_platform_staff());
create policy merchant_application_platform_manage on public.merchant_applications for update to authenticated using (private.is_platform_staff()) with check (private.is_platform_staff());
create trigger set_updated_at_goobt before update on public.merchant_applications for each row execute function private.set_updated_at();
