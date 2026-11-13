-- Enforce division/category consistency independently of the browser's category filter.
create or replace function private.validate_product_category_scope()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
 if NEW.category_id is not null and not exists(
  select 1 from public.categories c
  where c.id=NEW.category_id and c.division_id=NEW.division_id and c.status='active'
 ) then
  raise exception 'product_category_must_be_active_and_belong_to_division' using errcode='23514';
 end if;
 return NEW;
end;
$$;
revoke all on function private.validate_product_category_scope() from public,anon,authenticated;
drop trigger if exists validate_product_category_scope on public.products;
create trigger validate_product_category_scope
before insert or update of category_id,division_id on public.products
for each row execute function private.validate_product_category_scope();
