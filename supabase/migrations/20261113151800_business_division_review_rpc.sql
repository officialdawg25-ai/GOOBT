-- Audited platform review for division discovery status; it does not create/approve a legal merchant.
create or replace function private.review_business_division_impl(target_division_id uuid,target_status text,review_notes text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
 actor uuid;
 division public.business_divisions%rowtype;
 old_status text;
begin
 actor:=auth.uid();
 if actor is null or not exists(select 1 from public.platform_memberships pm where pm.user_id=actor and pm.role in ('platform_owner','platform_admin')) then
  raise exception 'platform_admin_required' using errcode='42501';
 end if;
 if target_status not in ('draft','active','paused','archived') then raise exception 'invalid_division_status' using errcode='22023'; end if;
 if nullif(trim(review_notes),'') is null then raise exception 'review_notes_required' using errcode='22023'; end if;
 select * into division from public.business_divisions where id=target_division_id for update;
 if not found then raise exception 'division_not_found' using errcode='P0002'; end if;
 old_status:=division.status;
 update public.business_divisions set status=target_status,updated_at=now() where id=target_division_id;
 insert into public.audit_events(actor_user_id,action,resource_type,resource_id,metadata)
 values(actor,'business_division_reviewed','business_division',target_division_id::text,jsonb_build_object('old_status',old_status,'new_status',target_status,'notes',trim(review_notes)));
 return jsonb_build_object('division_id',target_division_id,'status',target_status);
end;
$$;
revoke all on function private.review_business_division_impl(uuid,text,text) from public,anon;
grant execute on function private.review_business_division_impl(uuid,text,text) to authenticated;
create or replace function public.review_business_division(target_division_id uuid,target_status text,review_notes text)
returns jsonb language sql security invoker set search_path=''
as $$ select private.review_business_division_impl(target_division_id,target_status,review_notes); $$;
revoke all on function public.review_business_division(uuid,text,text) from public,anon;
grant execute on function public.review_business_division(uuid,text,text) to authenticated;
