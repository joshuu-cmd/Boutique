# Supabase setup for Ann's Boutique

The storefront and admin portal use Supabase Auth, the `products` table, and a public product-image bucket. Admin writes are restricted in PostgreSQL to user IDs explicitly added to `public.store_admins`; a successful sign-in by itself does not grant edit access.

## 1. Create and configure the project

1. Create a Supabase project and keep its database password private.
2. In **Authentication → Settings**, turn off **Allow new users to sign up**. Do not add a sign-up form to the site.
3. In the Supabase SQL Editor, run `supabase/schema.sql`.
4. In **Authentication → Users**, create Ann's user privately. Use the dashboard's create/invite-user flow and deliver credentials securely; do not put a password in this repository.
5. In the SQL Editor, allowlist that user's exact email (replace the example):

   ```sql
   insert into public.store_admins (user_id)
   select id from auth.users where lower(email) = lower('ann@example.com')
   on conflict (user_id) do nothing;
   ```

   Confirm exactly one row was inserted. If it inserted zero rows, the user has not been created or the email does not match. Never allowlist an email that Ann does not control. To revoke admin access, delete her row from `public.store_admins`.

## Update an existing project to the clothing categories

If you already ran the earlier version of `schema.sql`, open **SQL Editor → New query**, paste in `supabase/migrations/20260927_clothing_categories.sql`, and run it once. This replaces the original four demo products and their stock with clothing examples in **Pajamas**, **Innerwear**, and **Tops**, and removes products assigned to other categories. Export any real edits to those demo products before running it. Other products already assigned to one of the three new categories are preserved. New projects should use the current `supabase/schema.sql` instead.

The admin product editor uses the same three category values. Save a product after changing its category for the storefront filter to update.

## 2. Configure the website

1. In **Project Settings → API**, copy the Project URL and the public anon/publishable key.
2. Put those values in `supabase-config.js`:

   ```js
   export const SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";
   export const SUPABASE_ANON_KEY = "YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY";
   ```

   The public key is intended for browser use. **Never use or publish the `service_role` key, database password, or a user's password in the website.**
3. Serve the website over HTTP(S), such as with VS Code Live Server or a static host. ES modules and browser storage are not reliable when opening the pages as `file://` URLs.
4. Open `/admin.html`, sign in, edit a product, and verify the change appears on `/index.html`.

## Security notes

- Public account creation is disabled in Supabase; there is no client-side account-creation function.
- PostgreSQL row-level security permits public product reads but only allowlisted admin user IDs can modify product rows.
- Anyone can view product images because product photos must be public for the storefront. Only allowlisted admins can upload, replace, or delete files in the bucket.
- Protect the Supabase dashboard with multi-factor authentication. Keep project-owner access limited to trusted people.
- The shopping bag on this brochure storefront is still a visual demo and does not process orders or decrement inventory.
