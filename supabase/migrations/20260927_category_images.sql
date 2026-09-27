create table if not exists public.category_images (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('pajamas', 'innerwears', 'tops')),
  image_url text not null,
  image_alt text not null default '',
  storage_path text not null unique,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

alter table public.category_images enable row level security;

drop policy if exists "Anyone can view category images" on public.category_images;
create policy "Anyone can view category images"
  on public.category_images for select
  using (true);

drop policy if exists "Store admins can manage category images" on public.category_images;
create policy "Store admins can manage category images"
  on public.category_images for all
  to authenticated
  using (public.is_store_admin())
  with check (public.is_store_admin());

grant select on public.category_images to anon, authenticated;
grant insert, update, delete on public.category_images to authenticated;

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
