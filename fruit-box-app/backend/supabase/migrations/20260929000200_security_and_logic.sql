-- Fruit Box — roles, RLS, audit, pricing and order logic.
-- All customer-facing prices are computed HERE, never trusted from the client.

alter table audit_log add column branch_id text;

-- ───────────────────────── role helpers
create or replace function fb_is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from staff_roles where user_id = auth.uid() and role = 'owner')
$$;

create or replace function fb_is_content_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from staff_roles where user_id = auth.uid() and role = 'content_admin')
$$;

-- true if the user has one of the roles for that branch (owner always true)
create or replace function fb_has_branch_role(p_branch text, p_roles staff_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select fb_is_owner() or exists (
    select 1 from staff_roles
    where user_id = auth.uid() and branch_id = p_branch and role = any(p_roles))
$$;

create or replace function fb_is_staff_of(p_branch text) returns boolean
language sql stable security definer set search_path = public as $$
  select fb_has_branch_role(p_branch, array['branch_manager','order_staff']::staff_role[])
$$;

create or replace function fb_setting(p_key text) returns jsonb
language sql stable security definer set search_path = public as $$
  select value from app_settings where key = p_key
$$;

-- ───────────────────────── branch open check (branch timezone, past-midnight aware)
create or replace function fb_branch_is_open(p_branch text, p_at timestamptz default now()) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare tz text; local_ts timestamp; d smallint; t time; r record;
begin
  select timezone into tz from branches where id = p_branch and status = 'active';
  if tz is null then return false; end if;
  local_ts := p_at at time zone tz;
  d := extract(dow from local_ts); t := local_ts::time;
  for r in select * from branch_hours where branch_id = p_branch loop
    if r.opens <= r.closes then
      if r.weekday = d and t >= r.opens and t < r.closes then return true; end if;
    else -- crosses midnight: today after opens, or tomorrow-part before closes
      if (r.weekday = d and t >= r.opens) or (r.weekday = (d + 6) % 7 and t < r.closes) then return true; end if;
    end if;
  end loop;
  return false;
end $$;

-- ───────────────────────── prices (approved only) and offers (approved + in window)
create or replace function fb_base_price(p_branch text, p_product text, p_size text) returns int
language sql stable security definer set search_path = public as $$
  select price_fils from branch_product_prices
  where branch_id = p_branch and product_id = p_product and status = 'approved'
    and coalesce(size_id, '') = coalesce(p_size, '')
$$;

create or replace function fb_offer_price(p_branch text, p_product text, p_base int, p_at timestamptz default now()) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(min(case o.kind
      when 'percent'     then p_base - (p_base * o.value / 100)
      when 'amount_off'  then greatest(p_base - o.value, 0)
      when 'fixed_price' then least(o.value, p_base) end), p_base)
  from offers o
  where o.status = 'approved' and p_at >= o.starts_at and p_at < o.ends_at
    and p_product = any(o.product_ids)
    and (o.branch_ids is null or p_branch = any(o.branch_ids))
$$;

-- ───────────────────────── place order (the only way to create orders)
create or replace function place_order(
  p_branch text, p_service service_type, p_items jsonb,
  p_address uuid default null, p_coupon text default null, p_notes text default null)
returns orders
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  b branches; it jsonb; ad jsonb; pr products;
  unit int; addon_unit int; addons_total int; line int; subtotal int := 0;
  lines jsonb := '[]'; addons_out jsonb;
  disc int := 0; fee int := 0; vat int := 0; total int; cp coupons; dl branch_delivery_settings;
  o orders; incl boolean; rate int;
begin
  if uid is null then raise exception 'AUTH_REQUIRED' using errcode = 'P0001'; end if;
  insert into customers(id) values (uid) on conflict do nothing;

  select * into b from branches where id = p_branch;
  if b.id is null or b.status <> 'active' then raise exception 'BRANCH_UNAVAILABLE' using errcode = 'P0001'; end if;
  if not (p_service = any(b.services)) then raise exception 'SERVICE_UNAVAILABLE' using errcode = 'P0001'; end if;
  if not fb_branch_is_open(p_branch) then raise exception 'BRANCH_CLOSED' using errcode = 'P0001'; end if;
  if p_items is null or jsonb_array_length(p_items) = 0 then raise exception 'EMPTY_CART' using errcode = 'P0001'; end if;

  for it in select * from jsonb_array_elements(p_items) loop
    select * into pr from products where id = it->>'product_id' and is_active and content_status = 'approved';
    if pr.id is null then raise exception 'PRODUCT_UNAVAILABLE:%', it->>'product_id' using errcode = 'P0001'; end if;
    if exists (select 1 from branch_product_availability a where a.branch_id = p_branch and a.product_id = pr.id and not a.is_available) then
      raise exception 'PRODUCT_UNAVAILABLE:%', pr.id using errcode = 'P0001'; end if;
    if (it->>'size_id') is not null and not exists (select 1 from product_sizes s where s.id = it->>'size_id' and s.product_id = pr.id) then
      raise exception 'INVALID_SIZE:%', pr.id using errcode = 'P0001'; end if;
    unit := fb_base_price(p_branch, pr.id, it->>'size_id');
    if unit is null then raise exception 'PRICE_NOT_APPROVED:%', pr.id using errcode = 'P0001'; end if;
    unit := fb_offer_price(p_branch, pr.id, unit);

    addons_total := 0; addons_out := '[]';
    for ad in select * from jsonb_array_elements(coalesce(it->'addons', '[]')) loop
      select ap.price_fils into addon_unit from branch_addon_prices ap join product_addons pa on pa.id = ap.addon_id
        where ap.branch_id = p_branch and ap.addon_id = ad->>'id' and pa.product_id = pr.id and ap.status = 'approved'
          and coalesce((ad->>'qty')::int, 1) between 1 and pa.max_qty;
      if addon_unit is null then raise exception 'ADDON_UNAVAILABLE:%', ad->>'id' using errcode = 'P0001'; end if;
      addons_total := addons_total + addon_unit * coalesce((ad->>'qty')::int, 1);
      addons_out := addons_out || jsonb_build_object('id', ad->>'id', 'qty', coalesce((ad->>'qty')::int, 1), 'unit_price_fils', addon_unit);
    end loop;

    line := (unit + addons_total) * (it->>'qty')::int;
    subtotal := subtotal + line;
    lines := lines || jsonb_build_object('product_id', pr.id, 'size_id', it->>'size_id', 'qty', (it->>'qty')::int,
      'unit', unit, 'addons', addons_out, 'notes', left(it->>'notes', 200), 'line', line, 'name', pr.name_ar);
  end loop;

  if p_service = 'delivery' then
    select * into dl from branch_delivery_settings where branch_id = p_branch and status = 'approved';
    if dl.branch_id is null then raise exception 'DELIVERY_NOT_CONFIGURED' using errcode = 'P0001'; end if;
    if subtotal < coalesce(dl.min_order_fils, 0) then raise exception 'BELOW_MIN_ORDER' using errcode = 'P0001'; end if;
    if p_address is null or not exists (select 1 from addresses where id = p_address and customer_id = uid) then
      raise exception 'ADDRESS_REQUIRED' using errcode = 'P0001'; end if;
    fee := coalesce(dl.delivery_fee_fils, 0);
  end if;

  if p_coupon is not null then
    select * into cp from coupons where code = upper(p_coupon) and status = 'approved'
      and now() between starts_at and ends_at and (max_uses is null or used_count < max_uses) for update;
    if cp.code is null then raise exception 'COUPON_INVALID' using errcode = 'P0001'; end if;
    if subtotal < cp.min_subtotal_fils then raise exception 'COUPON_MIN_SUBTOTAL' using errcode = 'P0001'; end if;
    disc := case cp.kind when 'percent' then subtotal * cp.value / 100 else least(cp.value, subtotal) end;
    update coupons set used_count = used_count + 1 where code = cp.code;
  end if;

  total := subtotal - disc + fee;
  incl := coalesce((fb_setting('prices_include_vat'))::boolean, true);
  rate := coalesce((fb_setting('vat_rate_bp'))::int, 0);
  if incl then vat := round(total::numeric * rate / (10000 + rate));
  else vat := round(total::numeric * rate / 10000); total := total + vat; end if;

  insert into orders(customer_id, branch_id, service, address_id, status, payment_status,
                     subtotal_fils, discount_fils, delivery_fee_fils, vat_fils, total_fils, coupon_code, notes)
  values (uid, p_branch, p_service, p_address, 'pending_payment', 'pending',
          subtotal, disc, fee, vat, total, cp.code, left(p_notes, 300))
  returning * into o;

  insert into order_items(order_id, product_id, size_id, qty, unit_price_fils, addons, notes, line_total_fils, name_snapshot)
  select o.id, l->>'product_id', l->>'size_id', (l->>'qty')::int, (l->>'unit')::int, l->'addons', l->>'notes', (l->>'line')::int, l->>'name'
  from jsonb_array_elements(lines) l;

  insert into order_status_history(order_id, from_status, to_status, actor) values (o.id, null, o.status, uid);
  return o;
end $$;

-- sandbox payment confirmation — only possible when payments_mode = 'sandbox'
create or replace function confirm_payment_sandbox(p_order uuid) returns orders
language plpgsql security definer set search_path = public as $$
declare o orders;
begin
  if fb_setting('payments_mode') <> '"sandbox"'::jsonb then raise exception 'PAYMENTS_NOT_IN_SANDBOX' using errcode = 'P0001'; end if;
  update orders set payment_status = 'paid', status = 'placed'
    where id = p_order and customer_id = auth.uid() and status = 'pending_payment' returning * into o;
  if o.id is null then raise exception 'ORDER_NOT_PAYABLE' using errcode = 'P0001'; end if;
  insert into order_status_history(order_id, from_status, to_status, actor) values (o.id, 'pending_payment', 'placed', auth.uid());
  return o;
end $$;

-- ───────────────────────── order status transitions (staff + customer cancel)
create or replace function set_order_status(p_order uuid, p_to order_status, p_reason text default null) returns orders
language plpgsql security definer set search_path = public as $$
declare o orders; allowed order_status[];
begin
  select * into o from orders where id = p_order for update;
  if o.id is null then raise exception 'ORDER_NOT_FOUND' using errcode = 'P0001'; end if;

  if o.customer_id = auth.uid() and not fb_is_staff_of(o.branch_id) then
    if p_to <> 'cancelled' or o.status not in ('pending_payment','placed') then
      raise exception 'NOT_ALLOWED' using errcode = '42501'; end if;
  elsif not fb_is_staff_of(o.branch_id) then
    raise exception 'NOT_ALLOWED' using errcode = '42501';
  end if;

  allowed := case o.status
    when 'pending_payment'  then array['cancelled']
    when 'placed'           then array['accepted','rejected','cancelled']
    when 'accepted'         then array['preparing','cancelled']
    when 'preparing'        then array['ready','cancelled']
    when 'ready'            then array['out_for_delivery','completed']
    when 'out_for_delivery' then array['completed']
    else array[]::text[] end::order_status[];
  if not (p_to = any(allowed)) then raise exception 'INVALID_TRANSITION:%->%', o.status, p_to using errcode = 'P0001'; end if;
  if p_to = 'out_for_delivery' and o.service <> 'delivery' then raise exception 'INVALID_TRANSITION:pickup' using errcode = 'P0001'; end if;
  if p_to in ('cancelled','rejected') and coalesce(trim(p_reason), '') = '' then raise exception 'REASON_REQUIRED' using errcode = 'P0001'; end if;

  update orders set status = p_to, cancel_reason = case when p_to in ('cancelled','rejected') then p_reason else cancel_reason end
    where id = p_order returning * into o;
  insert into order_status_history(order_id, from_status, to_status, actor, reason)
    values (o.id, (select to_status from order_status_history where order_id = o.id order by id desc limit 1), p_to, auth.uid(), p_reason);
  return o;
end $$;

-- ───────────────────────── public menu (what apps, website, prerender and signage read)
create or replace function public_menu(p_branch text, p_at timestamptz default now()) returns jsonb
language sql stable security definer set search_path = public as $$
  select case when exists (select 1 from branches where id = p_branch and status in ('active','temporarily_closed'))
  then jsonb_build_object(
    'branch_id', p_branch,
    'generated_at', p_at,
    'categories', coalesce(jsonb_agg(c order by (c->>'sort')::int), '[]')) end
  from (
    select jsonb_build_object('id', cat.id, 'sort', cat.sort, 'name_ar', cat.name_ar, 'name_en', cat.name_en,
      'items', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', p.id, 'name_ar', p.name_ar, 'name_en', p.name_en, 'price_mode', p.price_mode,
          'image_path', p.image_path, 'description_ar', p.description_ar, 'description_en', p.description_en,
          'available', coalesce(a.is_available, true),
          'price_fils', fb_base_price(p_branch, p.id, null),
          'offer_price_fils', nullif(fb_offer_price(p_branch, p.id, fb_base_price(p_branch, p.id, null), p_at), fb_base_price(p_branch, p.id, null))
        ) order by p.sort)
        from products p left join branch_product_availability a on a.product_id = p.id and a.branch_id = p_branch
        where p.category_id = cat.id and p.is_active and p.content_status = 'approved'), '[]')) c
    from categories cat where cat.is_active
  ) s
$$;

-- ───────────────────────── guards: only owner approves; audit
create or replace function fb_guard_approval() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  n_st text := coalesce(to_jsonb(new)->>'status', to_jsonb(new)->>'content_status');
  o_st text := case when tg_op = 'UPDATE' then coalesce(to_jsonb(old)->>'status', to_jsonb(old)->>'content_status') end;
begin
  if n_st = 'approved' and o_st is distinct from 'approved' then
    if not fb_is_owner() and current_user not in ('postgres','service_role','supabase_admin') then
      raise exception 'ONLY_OWNER_CAN_APPROVE' using errcode = '42501'; end if;
    if tg_table_name in ('branch_product_prices','offers') then
      new.approved_by := auth.uid(); new.approved_at := now(); end if;
  end if;
  return new;
end $$;

create or replace function fb_audit() returns trigger
language plpgsql security definer set search_path = public as $$
declare o jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
        n jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
begin
  insert into audit_log(actor, table_name, row_pk, action, old_row, new_row, branch_id)
  values (auth.uid(), tg_table_name,
          coalesce(n->>'id', o->>'id', n->>'code', o->>'code', n->>'key', o->>'key', n->>'branch_id', o->>'branch_id'),
          lower(tg_op), o, n, coalesce(n->>'branch_id', o->>'branch_id'));
  return coalesce(new, old);
end $$;

create trigger guard_price  before insert or update on branch_product_prices for each row execute function fb_guard_approval();
create trigger guard_addonp before insert or update on branch_addon_prices   for each row execute function fb_guard_approval();
create trigger guard_offer  before insert or update on offers                for each row execute function fb_guard_approval();
create trigger guard_coupon before insert or update on coupons               for each row execute function fb_guard_approval();
create trigger guard_deliv  before insert or update on branch_delivery_settings for each row execute function fb_guard_approval();
create trigger guard_prod   before insert or update on products              for each row execute function fb_guard_approval();

do $$ declare t text; begin
  foreach t in array array['branch_product_prices','branch_addon_prices','staff_roles','offers','coupons',
                           'branches','branch_hours','branch_delivery_settings','app_settings','products',
                           'branch_product_availability'] loop
    execute format('create trigger audit_%1$s after insert or update or delete on %1$I for each row execute function fb_audit()', t);
  end loop;
end $$;
create trigger audit_orders after update of status, payment_status on orders for each row execute function fb_audit();

-- ───────────────────────── RLS
do $$ declare t text; begin
  foreach t in array array['app_settings','customers','staff_roles','branches','branch_hours','branch_delivery_settings',
    'categories','products','product_sizes','product_addons','branch_product_prices','branch_addon_prices',
    'branch_product_availability','offers','coupons','addresses','favorites','orders','order_items',
    'order_status_history','content_blocks','signage_screens','audit_log'] loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- settings: readable by all (no secrets live here), owner writes
create policy settings_read  on app_settings for select using (true);
create policy settings_write on app_settings for all using (fb_is_owner()) with check (fb_is_owner());

-- catalogue: public sees approved/active; owner + content admin write
create policy cat_read   on categories for select using (is_active or fb_is_owner() or fb_is_content_admin());
create policy cat_write  on categories for all using (fb_is_owner() or fb_is_content_admin()) with check (fb_is_owner() or fb_is_content_admin());
create policy prod_read  on products for select using ((is_active and content_status = 'approved') or fb_is_owner() or fb_is_content_admin()
                                                       or exists (select 1 from staff_roles where user_id = auth.uid()));
create policy prod_write on products for all using (fb_is_owner() or fb_is_content_admin()) with check (fb_is_owner() or fb_is_content_admin());
create policy size_read  on product_sizes  for select using (true);
create policy size_write on product_sizes  for all using (fb_is_owner() or fb_is_content_admin()) with check (fb_is_owner() or fb_is_content_admin());
create policy addon_read on product_addons for select using (true);
create policy addon_write on product_addons for all using (fb_is_owner() or fb_is_content_admin()) with check (fb_is_owner() or fb_is_content_admin());

-- branches
create policy br_read  on branches for select using (status in ('active','temporarily_closed') or exists (select 1 from staff_roles where user_id = auth.uid()));
create policy br_write on branches for all using (fb_is_owner()) with check (fb_is_owner());
create policy bh_read  on branch_hours for select using (true);
create policy bh_write on branch_hours for all using (fb_has_branch_role(branch_id, array['branch_manager']::staff_role[]))
                                               with check (fb_has_branch_role(branch_id, array['branch_manager']::staff_role[]));
create policy bd_read  on branch_delivery_settings for select using (status = 'approved' or fb_is_staff_of(branch_id));
create policy bd_write on branch_delivery_settings for all using (fb_is_owner()) with check (fb_is_owner());

-- prices: public sees approved only; ONLY owner writes (managers cannot change prices)
create policy bpp_read  on branch_product_prices for select using (status = 'approved' or fb_is_staff_of(branch_id));
create policy bpp_write on branch_product_prices for all using (fb_is_owner()) with check (fb_is_owner());
create policy bap_read  on branch_addon_prices for select using (status = 'approved' or fb_is_staff_of(branch_id));
create policy bap_write on branch_addon_prices for all using (fb_is_owner()) with check (fb_is_owner());

-- availability: branch manager + order staff of that branch
create policy av_read  on branch_product_availability for select using (true);
create policy av_write on branch_product_availability for all using (fb_is_staff_of(branch_id)) with check (fb_is_staff_of(branch_id));

-- offers: public sees approved & live; content admin drafts; owner approves (trigger)
create policy of_read  on offers for select using ((status = 'approved' and now() between starts_at and ends_at) or fb_is_owner() or fb_is_content_admin());
create policy of_write on offers for all using (fb_is_owner() or fb_is_content_admin()) with check (fb_is_owner() or fb_is_content_admin());
create policy cp_owner on coupons for all using (fb_is_owner()) with check (fb_is_owner());

-- customers & personal data
create policy cu_self   on customers for select using (id = auth.uid() or fb_is_owner()
  or exists (select 1 from orders o where o.customer_id = customers.id and fb_is_staff_of(o.branch_id)));
create policy cu_insert on customers for insert with check (id = auth.uid() and points_balance = 0);
create policy cu_update on customers for update using (id = auth.uid()) with check (id = auth.uid());
create policy ad_self  on addresses for all using (customer_id = auth.uid()) with check (customer_id = auth.uid());
create policy ad_staff on addresses for select using (exists (select 1 from orders o where o.address_id = addresses.id and fb_is_staff_of(o.branch_id)));
create policy fav_self on favorites for all using (customer_id = auth.uid()) with check (customer_id = auth.uid());

-- orders: read own / branch; writes only through functions (no insert/update policies)
create policy or_read on orders for select using (customer_id = auth.uid() or fb_is_staff_of(branch_id));
create policy oi_read on order_items for select using (exists (select 1 from orders o where o.id = order_id and (o.customer_id = auth.uid() or fb_is_staff_of(o.branch_id))));
create policy oh_read on order_status_history for select using (exists (select 1 from orders o where o.id = order_id and (o.customer_id = auth.uid() or fb_is_staff_of(o.branch_id))));

-- staff roles: owner manages; users see their own
create policy sr_read  on staff_roles for select using (user_id = auth.uid() or fb_is_owner());
create policy sr_write on staff_roles for all using (fb_is_owner()) with check (fb_is_owner());

-- content & signage
create policy cb_read  on content_blocks for select using ((status = 'approved' and (starts_at is null or now() >= starts_at) and (ends_at is null or now() < ends_at))
                                                          or fb_is_owner() or fb_is_content_admin());
create policy cb_write on content_blocks for all using (fb_is_owner() or fb_is_content_admin()) with check (fb_is_owner() or fb_is_content_admin());
create policy ss_read  on signage_screens for select using (true);
create policy ss_write on signage_screens for all using (fb_has_branch_role(branch_id, array['branch_manager']::staff_role[]) or fb_is_content_admin())
                                               with check (fb_has_branch_role(branch_id, array['branch_manager']::staff_role[]) or fb_is_content_admin());

-- audit: owner all, branch manager own branch; nobody writes directly
create policy au_read on audit_log for select using (fb_is_owner() or (branch_id is not null and fb_has_branch_role(branch_id, array['branch_manager']::staff_role[])));

-- grants (Supabase roles)
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
revoke insert, update, delete on orders, order_items, order_status_history, audit_log from authenticated;
grant execute on function place_order, set_order_status, confirm_payment_sandbox, public_menu, fb_branch_is_open to authenticated;
grant execute on function public_menu, fb_branch_is_open to anon;
