create table if not exists public.products (
  id text primary key,
  name text not null,
  detail text not null default '',
  price numeric(10, 2) not null default 0 check (price >= 0),
  image_url text not null,
  image_alt text not null default '',
  badge text not null default '',
  category text not null check (category in ('pajamas', 'innerwears', 'tops')),
  stock integer not null default 0 check (stock >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.category_images (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('pajamas', 'innerwears', 'tops')),
  image_url text not null,
  image_alt text not null default '',
  storage_path text not null unique,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.storefront_images (
  id text primary key check (id in ('hero', 'story')),
  image_url text not null,
  image_alt text not null default '',
  storage_path text,
  updated_at timestamptz not null default now()
);

create table if not exists public.hero_slides (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  image_alt text not null default '',
  storage_path text unique,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.category_images enable row level security;
alter table public.storefront_images enable row level security;
alter table public.hero_slides enable row level security;

create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.store_admins enable row level security;

create or replace function public.is_store_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.store_admins
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_store_admin() from public, anon;
grant execute on function public.is_store_admin() to authenticated;

drop policy if exists "Anyone can view products" on public.products;
create policy "Anyone can view products"
  on public.products for select
  using (true);

drop policy if exists "Store admins can manage products" on public.products;
create policy "Store admins can manage products"
  on public.products for all
  to authenticated
  using (public.is_store_admin())
  with check (public.is_store_admin());

grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;

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

insert into public.products (id, name, detail, price, image_url, image_alt, badge, category, stock)
values
  ('cotton-pajama-set', 'Cloud Soft Cotton Pajama Set', 'Breathable cotton · Cream', 68,
   'https://images.unsplash.com/photo-1576566588028-4147f3842f27?auto=format&fit=crop&w=700&q=80', 'Cloud Soft Cotton Pajama Set', 'Just arrived', 'pajamas', 12),
  ('lounge-pajama-set', 'The Sunday Lounge Pajama Set', 'Soft modal · Sage', 74,
   'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?auto=format&fit=crop&w=700&q=80', 'The Sunday Lounge Pajama Set', 'Bestseller', 'pajamas', 8),
  ('everyday-innerwear', 'Everyday Comfort Innerwear', 'Soft stretch · Neutral', 36,
   'https://images.unsplash.com/photo-1580237072617-771c3ecc4a24?auto=format&fit=crop&w=700&q=80', 'Everyday Comfort Innerwear', '', 'innerwears', 15),
  ('easy-linen-top', 'The Easy Linen Top', 'Linen blend · White', 52,
   'https://images.unsplash.com/photo-1551163943-3f6a855d1153?auto=format&fit=crop&w=700&q=80', 'The Easy Linen Top', 'Small batch', 'tops', 10)
on conflict (id) do nothing;

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
