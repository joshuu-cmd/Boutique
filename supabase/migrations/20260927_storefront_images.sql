create table if not exists public.storefront_images (
  id text primary key check (id in ('hero', 'story')),
  image_url text not null,
  image_alt text not null default '',
  storage_path text,
  updated_at timestamptz not null default now()
);

alter table public.storefront_images enable row level security;

drop policy if exists "Anyone can view storefront images" on public.storefront_images;
create policy "Anyone can view storefront images"
  on public.storefront_images for select
  using (true);

drop policy if exists "Store admins can manage storefront images" on public.storefront_images;
create policy "Store admins can manage storefront images"
  on public.storefront_images for all
  to authenticated
  using (public.is_store_admin())
  with check (public.is_store_admin());

grant select on public.storefront_images to anon, authenticated;
grant insert, update, delete on public.storefront_images to authenticated;

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
