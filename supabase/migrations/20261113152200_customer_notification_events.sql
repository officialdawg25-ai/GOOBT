-- Emit customer-owned in-app notifications for support intake, support status changes and merchant application review.
create or replace function private.notify_support_case_created()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
 insert into public.customer_notifications(customer_id,channel,title,body,resource_type,resource_id)
 values(NEW.customer_id,'in_app','Support request received',
  format('Your support request #%s was submitted. You can follow its status in GOOBT Support.',NEW.case_number),
  'support_case',NEW.id::text);
 return NEW;
end;
$$;
revoke all on function private.notify_support_case_created() from public,anon,authenticated;
drop trigger if exists notify_support_case_created on public.support_cases;
create trigger notify_support_case_created
after insert on public.support_cases
for each row execute function private.notify_support_case_created();

create or replace function private.update_support_case_impl(target_case_id uuid,target_status text,target_priority text,target_assignee uuid,review_notes text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
 actor uuid;
 support_case public.support_cases%rowtype;
 old_status text;
 old_priority text;
 old_assignee uuid;
 platform_actor boolean;
begin
 actor:=auth.uid();
 if actor is null then raise exception 'authentication_required' using errcode='42501'; end if;
 platform_actor:=exists(select 1 from public.platform_memberships pm where pm.user_id=actor and pm.role in ('platform_owner','platform_admin'));
 select * into support_case from public.support_cases where id=target_case_id for update;
 if not found then raise exception 'support_case_not_found' using errcode='P0002'; end if;
 if not platform_actor and (support_case.merchant_entity_id is null or not private.is_merchant_member(support_case.merchant_entity_id,array['owner','manager','support'])) then
  raise exception 'support_case_scope_denied' using errcode='42501';
 end if;
 if target_status not in ('open','in_progress','waiting_customer','resolved','closed') then raise exception 'invalid_support_status' using errcode='22023'; end if;
 if target_priority not in ('low','normal','high','urgent') then raise exception 'invalid_support_priority' using errcode='22023'; end if;
 if nullif(trim(review_notes),'') is null then raise exception 'support_review_notes_required' using errcode='22023'; end if;
 if target_assignee is not null then
  if support_case.merchant_entity_id is not null and not platform_actor then
   if not exists(select 1 from public.merchant_memberships mm where mm.merchant_entity_id=support_case.merchant_entity_id and mm.user_id=target_assignee and mm.role in ('owner','manager','support')) then
    raise exception 'assignee_not_in_merchant_support_team' using errcode='42501';
   end if;
  elsif platform_actor and not exists(select 1 from public.platform_memberships pm where pm.user_id=target_assignee and pm.role in ('platform_owner','platform_admin','platform_support')) then
   raise exception 'assignee_not_in_platform_support_team' using errcode='42501';
  end if;
 end if;
 old_status:=support_case.status;old_priority:=support_case.priority;old_assignee:=support_case.assigned_user_id;
 update public.support_cases set status=target_status,priority=target_priority,assigned_user_id=target_assignee,updated_at=now() where id=target_case_id;
 insert into public.audit_events(actor_user_id,merchant_entity_id,action,resource_type,resource_id,metadata)
 values(actor,support_case.merchant_entity_id,'support_case_updated','support_case',target_case_id::text,jsonb_build_object('old_status',old_status,'new_status',target_status,'old_priority',old_priority,'new_priority',target_priority,'old_assignee',old_assignee,'new_assignee',target_assignee,'notes',trim(review_notes)));
 insert into public.customer_notifications(customer_id,channel,title,body,resource_type,resource_id)
 values(support_case.customer_id,'in_app','Support case updated',
  format('Support case #%s is now %s (priority: %s).',support_case.case_number,replace(target_status,'_',' '),target_priority),
  'support_case',target_case_id::text);
 return jsonb_build_object('support_case_id',target_case_id,'status',target_status,'priority',target_priority,'assigned_user_id',target_assignee);
end;
$$;
revoke all on function private.update_support_case_impl(uuid,text,text,uuid,text) from public,anon;
grant execute on function private.update_support_case_impl(uuid,text,text,uuid,text) to authenticated;

create or replace function private.review_merchant_application_impl(application_id uuid,decision text,notes text default null)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
 app public.merchant_applications%rowtype;
 entity_id uuid;
 actor uuid;
 notification_title text;
 notification_body text;
begin
 actor:=auth.uid();
 if actor is null or not exists(select 1 from public.platform_memberships pm where pm.user_id=actor and pm.role in ('platform_owner','platform_admin')) then
  raise exception 'platform_admin_required' using errcode='42501';
 end if;
 if decision not in ('approve','reject','needs_information','under_review') then raise exception 'invalid_decision' using errcode='22023'; end if;
 select * into app from public.merchant_applications where id=application_id for update;
 if not found then raise exception 'application_not_found' using errcode='P0002'; end if;
 if app.status in ('approved','rejected','withdrawn') then raise exception 'application_already_finalized' using errcode='22000'; end if;
 if decision='approve' then
  insert into public.merchant_entities(division_id,legal_name,trading_name,registration_number,vat_number,country_code,status,merchant_of_record,settlement_status)
  values(app.division_id,app.legal_name,app.trading_name,app.registration_number,app.vat_number,app.country_code,'draft',false,'unverified')
  returning id into entity_id;
  insert into public.merchant_memberships(merchant_entity_id,user_id,role) values(entity_id,app.applicant_user_id,'owner');
  update public.merchant_applications set status='approved',review_notes=notes,reviewed_by=actor,reviewed_at=now(),merchant_entity_id=entity_id,updated_at=now() where id=application_id;
  insert into public.audit_events(actor_user_id,merchant_entity_id,action,resource_type,resource_id,metadata)
  values(actor,entity_id,'merchant_application_approved','merchant_application',application_id::text,jsonb_build_object('applicant_user_id',app.applicant_user_id,'division_id',app.division_id));
  notification_title:='Merchant application approved';
  notification_body:=format('Your application for %s has been approved. Your merchant entity is still in draft and settlement remains unverified; further checks are required before publishing.',app.trading_name);
  insert into public.customer_notifications(customer_id,channel,title,body,resource_type,resource_id)
  values(app.applicant_user_id,'in_app',notification_title,notification_body,'merchant_application',application_id::text);
  return entity_id;
 else
  update public.merchant_applications set status=case decision when 'reject' then 'rejected' when 'needs_information' then 'needs_information' else 'under_review' end,
   review_notes=notes,reviewed_by=actor,reviewed_at=now(),updated_at=now() where id=application_id;
  insert into public.audit_events(actor_user_id,action,resource_type,resource_id,metadata)
  values(actor,'merchant_application_reviewed','merchant_application',application_id::text,jsonb_build_object('decision',decision));
  notification_title:=case decision when 'reject' then 'Merchant application update' when 'needs_information' then 'More information requested' else 'Merchant application under review' end;
  notification_body:=case decision when 'reject' then format('Your merchant application for %s was not approved. Review the notes in your merchant workspace.',app.trading_name)
   when 'needs_information' then format('The review team needs more information for your application for %s. Please review the notes in your merchant workspace.',app.trading_name)
   else format('Your merchant application for %s is under review. You can check the status in your merchant workspace.',app.trading_name) end;
  insert into public.customer_notifications(customer_id,channel,title,body,resource_type,resource_id)
  values(app.applicant_user_id,'in_app',notification_title,notification_body,'merchant_application',application_id::text);
  return null;
 end if;
end;
$$;
revoke all on function private.review_merchant_application_impl(uuid,text,text) from public,anon;
grant execute on function private.review_merchant_application_impl(uuid,text,text) to authenticated;
