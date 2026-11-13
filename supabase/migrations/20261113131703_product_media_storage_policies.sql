-- Private product media bucket with published-catalogue read access and merchant-scoped writes.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('goobt-product-media','goobt-product-media',false,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=8388608,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

create policy goobt_product_media_public_read on storage.objects for select to anon
using(bucket_id='goobt-product-media' and exists(
 select 1 from public.product_media pm
 join public.products p on p.id=pm.product_id
 join public.merchant_entities m on m.id=p.merchant_entity_id
 join public.business_divisions d on d.id=p.division_id
 where pm.storage_path=storage.objects.name and p.status='active' and m.status='active' and m.settlement_status='approved' and d.status='active'
));
create policy goobt_product_media_authenticated_read on storage.objects for select to authenticated
using(bucket_id='goobt-product-media' and exists(
 select 1 from public.product_media pm
 join public.products p on p.id=pm.product_id
 join public.merchant_entities m on m.id=p.merchant_entity_id
 join public.business_divisions d on d.id=p.division_id
 where pm.storage_path=storage.objects.name and (
  (p.status='active' and m.status='active' and m.settlement_status='approved' and d.status='active')
  or private.is_merchant_member(m.id,array['owner','manager','catalogue'])
  or private.is_platform_staff()
 )
));
create policy goobt_product_media_merchant_insert on storage.objects for insert to authenticated
with check(bucket_id='goobt-product-media' and exists(
 select 1 from public.products p
 where p.id=nullif((storage.foldername(storage.objects.name))[2],'')::uuid
 and p.merchant_entity_id=nullif((storage.foldername(storage.objects.name))[1],'')::uuid
 and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff())
));
create policy goobt_product_media_merchant_update on storage.objects for update to authenticated
using(bucket_id='goobt-product-media' and exists(
 select 1 from public.products p
 where p.id=nullif((storage.foldername(storage.objects.name))[2],'')::uuid
 and p.merchant_entity_id=nullif((storage.foldername(storage.objects.name))[1],'')::uuid
 and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff())
))
with check(bucket_id='goobt-product-media' and exists(
 select 1 from public.products p
 where p.id=nullif((storage.foldername(storage.objects.name))[2],'')::uuid
 and p.merchant_entity_id=nullif((storage.foldername(storage.objects.name))[1],'')::uuid
 and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff())
));
create policy goobt_product_media_merchant_delete on storage.objects for delete to authenticated
using(bucket_id='goobt-product-media' and exists(
 select 1 from public.products p
 where p.id=nullif((storage.foldername(storage.objects.name))[2],'')::uuid
 and p.merchant_entity_id=nullif((storage.foldername(storage.objects.name))[1],'')::uuid
 and (private.is_merchant_member(p.merchant_entity_id,array['owner','manager','catalogue']) or private.is_platform_staff())
));
