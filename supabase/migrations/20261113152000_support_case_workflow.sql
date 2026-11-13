-- Customer support intake and audited status/priority handling.
create policy support_cases_customer_insert on public.support_cases for insert to authenticated
with check(customer_id=(select auth.uid()) and status='open' and priority='normal' and assigned_user_id is null);
create policy support_cases_platform_update on public.support_cases for update to authenticated
using(private.is_platform_staff()) with check(private.is_platform_staff());
create policy support_cases_merchant_update on public.support_cases for update to authenticated
using(merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager','support']))
with check(merchant_entity_id is not null and private.is_merchant_member(merchant_entity_id,array['owner','manager','support']));

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
 return jsonb_build_object('support_case_id',target_case_id,'status',target_status,'priority',target_priority,'assigned_user_id',target_assignee);
end;
$$;
revoke all on function private.update_support_case_impl(uuid,text,text,uuid,text) from public,anon;
grant execute on function private.update_support_case_impl(uuid,text,text,uuid,text) to authenticated;
create or replace function public.update_support_case(target_case_id uuid,target_status text,target_priority text,target_assignee uuid,review_notes text)
returns jsonb language sql security invoker set search_path=''
as $$ select private.update_support_case_impl(target_case_id,target_status,target_priority,target_assignee,review_notes); $$;
revoke all on function public.update_support_case(uuid,text,text,uuid,text) from public,anon;
grant execute on function public.update_support_case(uuid,text,text,uuid,text) to authenticated;
