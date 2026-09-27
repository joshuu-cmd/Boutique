-- Replace the original demo assortment with clothing-only starter products.
-- This intentionally resets product details and stock for the original four
-- demo rows, so export any real catalog changes before applying this migration.

alter table public.products
  drop constraint if exists products_category_check;

delete from public.products
where id in ('sunday-dress', 'shoulder-bag', 'golden-hoops', 'sunday-candle');

delete from public.products
where category not in ('pajamas', 'innerwears', 'tops');

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
on conflict (id) do update set
  name = excluded.name,
  detail = excluded.detail,
  price = excluded.price,
  image_url = excluded.image_url,
  image_alt = excluded.image_alt,
  badge = excluded.badge,
  category = excluded.category,
  stock = excluded.stock,
  updated_at = now();

alter table public.products
  add constraint products_category_check
  check (category in ('pajamas', 'innerwears', 'tops'));
