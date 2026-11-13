-- Controlled platform-only merchant entity status/settlement review, with mandatory audit notes.
create or replace function private.review_merchant_entity_impl(target_entity_id uuid,target_status text,target_settlement_status text,review_notes text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
 actor uuid;
 entity public.merchant_entities%rowtype;
 old_status text;
 old_settlement text;
begin
 actor:=auth.uid();
 if actor is null or not exists(select 1 from public.platform_memberships pm where pm.user_id=actor and pm.role in ('platform_owner','platform_admin')) then
  raise exception 'platform_admin_required' using errcode='42501';
 end if;
 if target_status not in ('draft','active','paused','archived') then raise exception 'invalid_merchant_status' using errcode='22023'; end if;
 if target_settlement_status not in ('unverified','pending_review','approved','suspended') then raise exception 'invalid_settlement_status' using errcode='22023'; end if;
 if nullif(trim(review_notes),'') is null then raise exception 'review_notes_required' using errcode='22023'; end if;
 if target_settlement_status='approved' and target_status<>'active' then raise exception 'settlement_approval_requires_active_entity' using errcode='22023'; end if;
 select * into entity from public.merchant_entities where id=target_entity_id for update;
 if not found then raise exception 'merchant_entity_not_found' using errcode='P0002'; end if;
 old_status:=entity.status;old_settlement:=entity.settlement_status;
 update public.merchant_entities set status=target_status,settlement_status=target_settlement_status,updated_at=now() where id=target_entity_id;
 insert into public.audit_events(actor_user_id,merchant_entity_id,action,resource_type,resource_id,metadata)
 values(actor,target_entity_id,'merchant_entity_reviewed','merchant_entity',target_entity_id::text,jsonb_build_object('old_status',old_status,'new_status',target_status,'old_settlement_status',old_settlement,'new_settlement_status',target_settlement_status,'notes',trim(review_notes)));
 return jsonb_build_object('merchant_entity_id',target_entity_id,'status',target_status,'settlement_status',target_settlement_status);
end;
$$;
revoke all on function private.review_merchant_entity_impl(uuid,text,text,text) from public,anon;
grant execute on function private.review_merchant_entity_impl(uuid,text,text,text) to authenticated;
create or replace function public.review_merchant_entity(target_entity_id uuid,target_status text,target_settlement_status text,review_notes text)
returns jsonb language sql security invoker set search_path=''
as $$ select private.review_merchant_entity_impl(target_entity_id,target_status,target_settlement_status,review_notes); $$;
revoke all on function public.review_merchant_entity(uuid,text,text,text) from public,anon;
grant execute on function public.review_merchant_entity(uuid,text,text,text) to authenticated;
