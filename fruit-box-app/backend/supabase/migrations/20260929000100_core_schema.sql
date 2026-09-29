-- Fruit Box — core schema (Supabase / PostgreSQL 15+)
-- Money is integer fils (1 AED = 100 fils). Nothing customer-visible is shown
-- unless it is APPROVED (prices, offers, branch data).

create extension if not exists pgcrypto;

-- ───────────────────────── enums
create type staff_role      as enum ('owner','branch_manager','order_staff','content_admin');
create type approval_status as enum ('draft','pending_approval','approved','archived');
create type branch_status   as enum ('pending_owner_data','active','temporarily_closed','closed');
create type price_mode      as enum ('fixed','by_selection');
create type service_type    as enum ('delivery','pickup');
create type order_status    as enum ('pending_payment','placed','accepted','preparing','ready','out_for_delivery','completed','cancelled','rejected');
create type payment_status  as enum ('not_required','pending','paid','failed','refunded');
create type offer_kind      as enum ('percent','fixed_price','amount_off');

-- ───────────────────────── settings (domain/email are TARGET values only)
create table app_settings (
  key text primary key,
  value jsonb not null,
  note text,
  updated_at timestamptz not null default now()
);
insert into app_settings(key, value, note) values
 ('target_domain',          '"fruitbox.com"',        'Target only. Ownership NOT confirmed. Do not deploy/link production to it.'),
 ('target_support_email',   '"info@fruitbox.com"',   'Target only. Mailbox NOT created/verified.'),
 ('email_sending_enabled',  'false',                 'Must stay false until the owner confirms the domain and tests the mailbox.'),
 ('blocked_domains',        '["futitbox.com"]',      'Mistakenly registered domain. Must never appear in brand or product links.'),
 ('payments_mode',          '"disabled"',            'disabled | sandbox | live — requires owner decision + provider account.'),
 ('prices_include_vat',     'true',                  'PENDING OWNER CONFIRMATION (UAE VAT 5%).'),
 ('vat_rate_bp',            '500',                   'Basis points. 500 = 5%. Pending confirmation.'),
 ('points_per_aed',         '0',                     'Loyalty earning rate — 0 until the owner approves a programme.');

-- ───────────────────────── people & roles
create table customers (
  id uuid primary key,                       -- = auth.users.id
  full_name text,
  phone text,
  locale text not null default 'ar' check (locale in ('ar','en')),
  points_balance int not null default 0 check (points_balance >= 0),
  created_at timestamptz not null default now()
);

create table staff_roles (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  role staff_role not null,
  branch_id text,                            -- null only for owner/content_admin
  created_at timestamptz not null default now(),
  unique (user_id, role, branch_id),
  check ((role in ('branch_manager','order_staff')) = (branch_id is not null))
);

-- ───────────────────────── branches
create table branches (
  id text primary key,
  name_ar text not null,
  name_en text,
  address_ar text, address_en text,
  lat double precision, lng double precision,
  phone text,
  timezone text not null default 'Asia/Dubai',
  services service_type[] not null default '{}',
  status branch_status not null default 'pending_owner_data',
  approved_by uuid, approved_at timestamptz,
  created_at timestamptz not null default now()
);
alter table staff_roles add foreign key (branch_id) references branches(id);

create table branch_hours (
  branch_id text references branches(id) on delete cascade,
  weekday smallint check (weekday between 0 and 6),   -- 0 = Sunday
  opens time not null,
  closes time not null,                                -- closes < opens ⇒ past midnight
  primary key (branch_id, weekday, opens)
);

create table branch_delivery_settings (
  branch_id text primary key references branches(id) on delete cascade,
  delivery_fee_fils int check (delivery_fee_fils >= 0),
  min_order_fils int check (min_order_fils >= 0),
  status approval_status not null default 'draft'
);

-- ───────────────────────── catalogue
create table categories (
  id text primary key,
  sort int not null default 0,
  name_ar text not null,
  name_en text,
  is_active boolean not null default true,
  spelling_review text not null default 'pending'
);

create table products (
  id text primary key,
  category_id text not null references categories(id),
  sort int not null default 0,
  name_ar text not null,
  name_en text,
  description_ar text, description_en text,
  image_path text,                         -- ORIGINAL photos only, via Storage
  price_mode price_mode not null,
  allergens text,                          -- null until approved; never guessed
  spelling_review text not null default 'pending',
  content_status approval_status not null default 'draft',
  is_active boolean not null default true
);

create table product_sizes (
  id text primary key,
  product_id text not null references products(id) on delete cascade,
  sort int not null default 0,
  name_ar text not null, name_en text
);

create table product_addons (
  id text primary key,
  product_id text not null references products(id) on delete cascade,
  sort int not null default 0,
  name_ar text not null, name_en text,
  max_qty int not null default 1 check (max_qty between 1 and 10)
);

-- price per branch (and per size). Visible only when approved.
create table branch_product_prices (
  id bigint generated always as identity primary key,
  branch_id text not null references branches(id) on delete cascade,
  product_id text not null references products(id) on delete cascade,
  size_id text references product_sizes(id) on delete cascade,
  price_fils int not null check (price_fils > 0),
  status approval_status not null default 'draft',
  source text,                                -- e.g. 'talabat_observed_2026-09-29'
  approved_by uuid, approved_at timestamptz
);
create unique index bpp_unique on branch_product_prices (branch_id, product_id, coalesce(size_id, ''));

create table branch_addon_prices (
  branch_id text not null references branches(id) on delete cascade,
  addon_id text not null references product_addons(id) on delete cascade,
  price_fils int not null check (price_fils >= 0),
  status approval_status not null default 'draft',
  primary key (branch_id, addon_id)
);

create table branch_product_availability (
  branch_id text not null references branches(id) on delete cascade,
  product_id text not null references products(id) on delete cascade,
  is_available boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (branch_id, product_id)
);

-- ───────────────────────── offers, coupons
create table offers (
  id text primary key,
  title_ar text not null, title_en text,
  kind offer_kind not null,
  value int not null check (value > 0),      -- percent (1..100) | fils
  product_ids text[] not null default '{}',
  branch_ids text[],                         -- null = all branches
  starts_at timestamptz,                     -- may be unknown while draft
  ends_at timestamptz,
  status approval_status not null default 'draft',
  source text,
  approved_by uuid, approved_at timestamptz,
  check (kind <> 'percent' or value <= 100),
  check (ends_at is null or starts_at is null or ends_at > starts_at),
  check (status <> 'approved' or (starts_at is not null and ends_at is not null))
);

create table coupons (
  code text primary key check (code = upper(code)),
  kind offer_kind not null check (kind in ('percent','amount_off')),
  value int not null check (value > 0),
  min_subtotal_fils int not null default 0,
  max_uses int, used_count int not null default 0,
  starts_at timestamptz not null, ends_at timestamptz not null,
  status approval_status not null default 'draft'
);

-- ───────────────────────── customer data
create table addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers(id) on delete cascade,
  label text, details text not null,
  lat double precision, lng double precision,
  created_at timestamptz not null default now()
);

create table favorites (
  customer_id uuid references customers(id) on delete cascade,
  product_id text references products(id) on delete cascade,
  primary key (customer_id, product_id)
);

-- ───────────────────────── orders
create sequence order_number_seq start 1001;
create table orders (
  id uuid primary key default gen_random_uuid(),
  number bigint not null unique default nextval('order_number_seq'),
  customer_id uuid not null references customers(id),
  branch_id text not null references branches(id),
  service service_type not null,
  address_id uuid references addresses(id),
  status order_status not null default 'placed',
  payment_status payment_status not null default 'pending',
  subtotal_fils int not null, discount_fils int not null default 0,
  delivery_fee_fils int not null default 0, vat_fils int not null default 0,
  total_fils int not null,
  coupon_code text references coupons(code),
  notes text,
  cancel_reason text,
  created_at timestamptz not null default now(),
  check (total_fils >= 0),
  check (service = 'pickup' or address_id is not null)
);

create table order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references orders(id) on delete cascade,
  product_id text not null references products(id),
  size_id text references product_sizes(id),
  qty int not null check (qty between 1 and 50),
  unit_price_fils int not null,
  addons jsonb not null default '[]',        -- [{id, qty, unit_price_fils}]
  notes text check (char_length(notes) <= 200),
  line_total_fils int not null,
  name_snapshot text not null
);

create table order_status_history (
  id bigint generated always as identity primary key,
  order_id uuid not null references orders(id) on delete cascade,
  from_status order_status, to_status order_status not null,
  actor uuid, reason text,
  at timestamptz not null default now()
);

-- ───────────────────────── content for app / site / signage
create table content_blocks (
  id text primary key,
  surface text not null check (surface in ('app','website','signage')),
  branch_id text references branches(id),
  locale text not null check (locale in ('ar','en')),
  body jsonb not null,
  starts_at timestamptz, ends_at timestamptz,
  status approval_status not null default 'draft'
);

create table signage_screens (
  id text primary key,
  branch_id text not null references branches(id),
  name text not null,
  locale_mode text not null default 'alternate' check (locale_mode in ('ar','en','alternate')),
  playlist jsonb not null default '[]',      -- [{template, ref, seconds}]
  last_seen_at timestamptz
);

-- ───────────────────────── audit log
create table audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  actor uuid,
  table_name text not null,
  row_pk text,
  action text not null,
  old_row jsonb, new_row jsonb
);
