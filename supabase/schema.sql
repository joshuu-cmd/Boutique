create table if not exists public.products (
  id text primary key,
  name text not null,
  detail text not null default '',
  price numeric(10, 2) not null default 0 check (price >= 0),
  image_url text not null,
  image_alt text not null default '',
  badge text not null default '',
  category text not null,
  stock integer not null default 0 check (stock >= 0),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;

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

insert into public.products (id, name, detail, price, image_url, image_alt, badge, category, stock)
values
  ('sunday-dress', 'The Sunday Midi Dress', 'Soft cotton · Sage', 88,
   'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&w=700&q=80', 'The Sunday Midi Dress', 'Just arrived', 'clothing', 12),
  ('shoulder-bag', 'The Everyday Shoulder Bag', 'Vegan leather · Toffee', 74,
   'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=700&q=80', 'The Everyday Shoulder Bag', 'Bestseller', 'accessories', 8),
  ('golden-hoops', 'Golden Hour Hoops', '14k gold vermeil', 42,
   'https://images.unsplash.com/photo-1611652022419-a9419f74343d?auto=format&fit=crop&w=700&q=80', 'Golden Hour Hoops', '', 'accessories', 15),
  ('sunday-candle', 'Sunday Morning Candle', 'Hand-poured · 8 oz', 32,
   'https://images.unsplash.com/photo-1603006905003-be475563bc59?auto=format&fit=crop&w=700&q=80', 'Sunday Morning Candle', 'Small batch', 'home', 10)
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
