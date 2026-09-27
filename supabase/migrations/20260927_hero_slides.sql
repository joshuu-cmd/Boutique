create table if not exists public.hero_slides (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  image_alt text not null default '',
  storage_path text unique,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

alter table public.hero_slides enable row level security;

drop policy if exists "Anyone can view hero slides" on public.hero_slides;
create policy "Anyone can view hero slides"
  on public.hero_slides for select
  using (true);

drop policy if exists "Store admins can manage hero slides" on public.hero_slides;
create policy "Store admins can manage hero slides"
  on public.hero_slides for all
  to authenticated
  using (public.is_store_admin())
  with check (public.is_store_admin());

grant select on public.hero_slides to anon, authenticated;
grant insert, update, delete on public.hero_slides to authenticated;

insert into public.hero_slides (image_url, image_alt, storage_path, sort_order)
select image_url, image_alt, storage_path, 0
from public.storefront_images
where id = 'hero'
  and not exists (select 1 from public.hero_slides);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 8388608, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Admins can upload product images" on storage.objects;
create policy "Admins can upload product images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-images' and public.is_store_admin());

drop policy if exists "Admins can update product images" on storage.objects;
create policy "Admins can update product images"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'product-images' and public.is_store_admin())
  with check (bucket_id = 'product-images' and public.is_store_admin());

drop policy if exists "Admins can delete product images" on storage.objects;
create policy "Admins can delete product images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'product-images' and public.is_store_admin());
