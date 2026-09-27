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
