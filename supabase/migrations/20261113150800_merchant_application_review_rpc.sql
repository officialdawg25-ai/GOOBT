-- Authenticated applicants can see draft divisions to select where to apply; anonymous discovery remains active-only.
create policy divisions_authenticated_draft_read on public.business_divisions for select to authenticated using (status in ('active','draft'));

-- Platform-admin approval creates merchant entity and grants applicant owner membership atomically.
create or replace function public.review_merchant_application(application_id uuid, decision text, notes text default null)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
 app public.merchant_applications%rowtype;
 entity_id uuid;
 actor uuid;
begin
 actor := auth.uid();
 if actor is null or not exists(
  select 1 from public.platform_memberships pm
  where pm.user_id=actor and pm.role in ('platform_owner','platform_admin')
 ) then
  raise exception 'platform_admin_required' using errcode='42501';
 end if;
 if decision not in ('approve','reject','needs_information','under_review') then
  raise exception 'invalid_decision' using errcode='22023';
 end if;
 select * into app from public.merchant_applications where id=application_id for update;
 if not found then raise exception 'application_not_found' using errcode='P0002'; end if;
 if app.status in ('approved','rejected','withdrawn') then raise exception 'application_already_finalized' using errcode='22000'; end if;
 if decision='approve' then
  insert into public.merchant_entities(division_id,legal_name,trading_name,registration_number,vat_number,country_code,status,merchant_of_record,settlement_status)
  values(app.division_id,app.legal_name,app.trading_name,app.registration_number,app.vat_number,app.country_code,'draft',false,'unverified')
  returning id into entity_id;
  insert into public.merchant_memberships(merchant_entity_id,user_id,role)
  values(entity_id,app.applicant_user_id,'owner');
  update public.merchant_applications set status='approved',review_notes=notes,reviewed_by=actor,reviewed_at=now(),merchant_entity_id=entity_id,updated_at=now()
  where id=application_id;
  insert into public.audit_events(actor_user_id,merchant_entity_id,action,resource_type,resource_id,metadata)
  values(actor,entity_id,'merchant_application_approved','merchant_application',application_id::text,jsonb_build_object('applicant_user_id',app.applicant_user_id,'division_id',app.division_id));
  return entity_id;
 else
  update public.merchant_applications set status=case decision when 'reject' then 'rejected' when 'needs_information' then 'needs_information' else 'under_review' end,
  review_notes=notes,reviewed_by=actor,reviewed_at=now(),updated_at=now()
  where id=application_id;
  insert into public.audit_events(actor_user_id,action,resource_type,resource_id,metadata)
  values(actor,'merchant_application_reviewed','merchant_application',application_id::text,jsonb_build_object('decision',decision));
  return null;
 end if;
end;
$$;
revoke all on function public.review_merchant_application(uuid,text,text) from public,anon;
grant execute on function public.review_merchant_application(uuid,text,text) to authenticated;
