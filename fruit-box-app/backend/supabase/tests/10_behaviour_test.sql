-- Behaviour tests: roles, RLS, approvals, server-side pricing, order lifecycle, audit.
-- Run with: psql -v ON_ERROR_STOP=1 -f 10_behaviour_test.sql   (see tools/test_backend.sh)
\set QUIET on
\pset tuples_only on

-- test helpers ---------------------------------------------------------------
create or replace function pg_temp.expect_error(sql text, needle text) returns void language plpgsql as $$
begin
  execute sql;
  raise exception 'EXPECTED ERROR "%" BUT STATEMENT SUCCEEDED: %', needle, sql;
exception when others then
  if position(needle in sqlerrm) = 0 then raise exception 'EXPECTED "%" GOT "%" FOR: %', needle, sqlerrm, sql; end if;
end $$;
create or replace function pg_temp.eq(label text, got anyelement, want anyelement) returns text language plpgsql as $$
begin
  if got is distinct from want then raise exception 'FAIL % — got % want %', label, got, want; end if;
  return 'ok  ' || label;
end $$;

-- users
\set OWNER   '''00000000-0000-0000-0000-0000000000a1'''
\set MGR4    '''00000000-0000-0000-0000-0000000000b4'''
\set STAFF4  '''00000000-0000-0000-0000-0000000000c4'''
\set CONTENT '''00000000-0000-0000-0000-0000000000d1'''
\set MGR5    '''00000000-0000-0000-0000-0000000000b5'''
\set CUST1   '''00000000-0000-0000-0000-0000000000e1'''
\set CUST2   '''00000000-0000-0000-0000-0000000000e2'''
insert into staff_roles(user_id, role, branch_id) values
 (:OWNER, 'owner', null), (:MGR4, 'branch_manager', 'br_04'), (:STAFF4, 'order_staff', 'br_04'),
 (:CONTENT, 'content_admin', null), (:MGR5, 'branch_manager', 'br_05');

-- 1. seed integrity -------------------------------------------------------------
select pg_temp.eq('14 categories', (select count(*) from categories), 14::bigint);
select pg_temp.eq('110 products', (select count(*) from products), 110::bigint);
select pg_temp.eq('38 fixed', (select count(*) from products where price_mode='fixed'), 38::bigint);
select pg_temp.eq('72 by_selection', (select count(*) from products where price_mode='by_selection'), 72::bigint);
select pg_temp.eq('38 observed prices only at New Shahama', (select count(*) from branch_product_prices where branch_id='br_04'), 38::bigint);
select pg_temp.eq('no prices copied to other branches', (select count(*) from branch_product_prices where branch_id<>'br_04'), 0::bigint);
select pg_temp.eq('nothing approved at seed', (select count(*) from branch_product_prices where status='approved'), 0::bigint);
select pg_temp.eq('11 branches pending data', (select count(*) from branches where status='pending_owner_data'), 11::bigint);
select pg_temp.eq('desserts regular price 45 AED', (select min(price_fils) from branch_product_prices where product_id like 'cat_13_%'), 4500);
select pg_temp.eq('email sending disabled', (select value from app_settings where key='email_sending_enabled'), 'false'::jsonb);
select pg_temp.eq('futitbox only in block list', (select count(*) from app_settings where value::text like '%futitbox%' and key<>'blocked_domains'), 0::bigint);

-- 2. anonymous visitor sees nothing unapproved ----------------------------------
set role anon;
select pg_temp.eq('anon: no unapproved products', (select count(*) from products), 0::bigint);
select pg_temp.eq('anon: no unapproved prices', (select count(*) from branch_product_prices), 0::bigint);
select pg_temp.eq('anon: pending branches hidden', (select count(*) from branches), 0::bigint);
select pg_temp.eq('anon: public_menu of inactive branch is null', (select public_menu('br_04')), null::jsonb);
reset role;

-- 3. non-owners cannot approve or change prices --------------------------------
select set_config('request.jwt.claim.sub', :MGR4, false); set role authenticated;
update branch_product_prices set price_fils = 1 where branch_id='br_04';
select pg_temp.eq('manager cannot change prices (0 rows)', (select count(*) from branch_product_prices where price_fils=1), 0::bigint);
reset role;
select set_config('request.jwt.claim.sub', :CONTENT, false); set role authenticated;
select pg_temp.expect_error($$update products set content_status='approved' where id='cat_03_item_01'$$, 'ONLY_OWNER_CAN_APPROVE');
update products set description_ar = 'وصف تجريبي' where id = 'cat_03_item_01';
select pg_temp.eq('content admin can edit description', (select description_ar from products where id='cat_03_item_01'), 'وصف تجريبي');
reset role;

-- 4. owner activates New Shahama and approves "الأصناف الجديدة" -------------------
select set_config('request.jwt.claim.sub', :OWNER, false); set role authenticated;
update branches set status='active', services='{pickup,delivery}' where id='br_04';
insert into branch_hours select 'br_04', d, '00:00', '23:59:59' from generate_series(0,6) d;
update products set content_status='approved' where category_id in ('cat_03','cat_10');
update branch_product_prices set status='approved' where branch_id='br_04' and product_id like 'cat_03_%';
reset role;
select pg_temp.eq('approval stamped with owner', (select count(*) from branch_product_prices where status='approved' and approved_by=:OWNER::uuid), 5::bigint);
select pg_temp.eq('price approvals audited with actor',
  (select count(*) from audit_log where table_name='branch_product_prices' and action='update' and actor=:OWNER::uuid), 5::bigint);

set role anon;
select pg_temp.eq('anon: approved New items visible', (select count(*) from products where category_id='cat_03'), 5::bigint);
select pg_temp.eq('anon: public_menu lists approved price 30 AED',
  (select (x->>'price_fils')::int from jsonb_array_elements((select public_menu('br_04'))->'categories') c,
          jsonb_array_elements(c->'items') x where x->>'id'='cat_03_item_01'), 3000);
select pg_temp.eq('anon: ice cream visible but price hidden (not approved)',
  (select x->>'price_fils' from jsonb_array_elements((select public_menu('br_04'))->'categories') c,
          jsonb_array_elements(c->'items') x where x->>'id'='cat_10_item_01'), null::text);
reset role;

-- 5. customer places an order; server ignores any client price ------------------
select set_config('request.jwt.claim.sub', :CUST1, false); set role authenticated;
select pg_temp.expect_error($$insert into orders(customer_id, branch_id, service, subtotal_fils, total_fils) values (auth.uid(),'br_04','pickup',1,1)$$, 'permission denied');
create temp table o1 as select * from place_order('br_04', 'pickup',
  '[{"product_id":"cat_03_item_01","qty":2,"unit_price_fils":1}]'::jsonb);
select pg_temp.eq('subtotal from DB price (2 × 30 AED)', (select subtotal_fils from o1), 6000);
select pg_temp.eq('VAT 5% included = 2.86 AED', (select vat_fils from o1), 286);
select pg_temp.eq('total 60 AED', (select total_fils from o1), 6000);
select pg_temp.eq('awaiting payment', (select status::text from o1), 'pending_payment');
select pg_temp.expect_error($$select place_order('br_04','pickup','[{"product_id":"cat_10_item_01","qty":1}]')$$, 'PRICE_NOT_APPROVED');
select pg_temp.expect_error($$select place_order('br_04','pickup','[{"product_id":"cat_01_item_01","qty":1}]')$$, 'PRODUCT_UNAVAILABLE');
select pg_temp.expect_error($$select place_order('br_04','delivery','[{"product_id":"cat_03_item_01","qty":1}]')$$, 'DELIVERY_NOT_CONFIGURED');
select pg_temp.expect_error($$select place_order('br_05','pickup','[{"product_id":"cat_03_item_01","qty":1}]')$$, 'BRANCH_UNAVAILABLE');
select pg_temp.expect_error($$select place_order('br_04','pickup','[]')$$, 'EMPTY_CART');
select pg_temp.expect_error($$select place_order('br_04','pickup','[{"product_id":"cat_03_item_01","qty":1}]', null, 'NOPE')$$, 'COUPON_INVALID');
select pg_temp.expect_error($$select confirm_payment_sandbox((select id from orders limit 1))$$, 'PAYMENTS_NOT_IN_SANDBOX');
reset role;

-- 6. isolation between customers and branches ---------------------------------
select set_config('request.jwt.claim.sub', :CUST2, false); set role authenticated;
select pg_temp.eq('customer 2 cannot see customer 1 orders', (select count(*) from orders), 0::bigint);
reset role;
select set_config('request.jwt.claim.sub', :MGR5, false); set role authenticated;
select pg_temp.eq('other-branch manager cannot see br_04 orders', (select count(*) from orders), 0::bigint);
select pg_temp.eq('other-branch manager cannot read br_04 audit', (select count(*) from audit_log where branch_id='br_04'), 0::bigint);
reset role;
select set_config('request.jwt.claim.sub', :MGR4, false); set role authenticated;
select pg_temp.eq('branch manager sees own branch orders', (select count(*) from orders), 1::bigint);
select pg_temp.eq('branch manager reads own branch audit', (select count(*) > 0 from audit_log where branch_id='br_04'), true);
reset role;

-- 7. order lifecycle by staff --------------------------------------------------
update app_settings set value='"sandbox"' where key='payments_mode';
select set_config('request.jwt.claim.sub', :CUST1, false); set role authenticated;
select pg_temp.eq('sandbox payment moves to placed', (select status::text from confirm_payment_sandbox((select id from o1))), 'placed');
reset role;
select set_config('request.jwt.claim.sub', :STAFF4, false); set role authenticated;
select pg_temp.expect_error(format($$select set_order_status(%L,'rejected')$$, (select id from o1)), 'REASON_REQUIRED');
select pg_temp.expect_error(format($$select set_order_status(%L,'completed')$$, (select id from o1)), 'INVALID_TRANSITION');
select pg_temp.eq('accept',   (select status::text from set_order_status((select id from o1),'accepted')), 'accepted');
select pg_temp.eq('prepare',  (select status::text from set_order_status((select id from o1),'preparing')), 'preparing');
select pg_temp.eq('ready',    (select status::text from set_order_status((select id from o1),'ready')), 'ready');
select pg_temp.expect_error(format($$select set_order_status(%L,'out_for_delivery')$$, (select id from o1)), 'INVALID_TRANSITION');
select pg_temp.eq('complete', (select status::text from set_order_status((select id from o1),'completed')), 'completed');
select pg_temp.eq('status history recorded', (select count(*) from order_status_history where order_id=(select id from o1)), 6::bigint);
-- availability toggle by order staff
insert into branch_product_availability(branch_id, product_id, is_available) values ('br_04','cat_03_item_02', false);
reset role;
select set_config('request.jwt.claim.sub', :CUST1, false); set role authenticated;
select pg_temp.expect_error($$select place_order('br_04','pickup','[{"product_id":"cat_03_item_02","qty":1}]')$$, 'PRODUCT_UNAVAILABLE');
select pg_temp.expect_error(format($$select set_order_status(%L,'cancelled','x')$$, (select id from o1)), 'NOT_ALLOWED');
reset role;
select set_config('request.jwt.claim.sub', :MGR5, false); set role authenticated;
select pg_temp.expect_error(format($$select set_order_status(%L,'accepted')$$, (select id from o1)), 'NOT_ALLOWED');
reset role;

-- 8. offers: only approved + in window apply -----------------------------------
select set_config('request.jwt.claim.sub', :OWNER, false); set role authenticated;
update products set content_status='approved' where category_id='cat_13';
update branch_product_prices set status='approved' where branch_id='br_04' and product_id like 'cat_13_%';
reset role;
select set_config('request.jwt.claim.sub', :CUST1, false); set role authenticated;
select pg_temp.eq('draft offer NOT applied (45 AED)',
  (select subtotal_fils from place_order('br_04','pickup','[{"product_id":"cat_13_item_01","qty":1}]')), 4500);
reset role;
select set_config('request.jwt.claim.sub', :CONTENT, false); set role authenticated;
select pg_temp.expect_error($$update offers set status='approved', starts_at=now()-interval '1 day', ends_at=now()+interval '1 day'$$, 'ONLY_OWNER_CAN_APPROVE');
reset role;
select set_config('request.jwt.claim.sub', :OWNER, false); set role authenticated;
update offers set status='approved', starts_at=now()-interval '1 day', ends_at=now()+interval '1 day' where id='offer_desserts_observed';
reset role;
select set_config('request.jwt.claim.sub', :CUST1, false); set role authenticated;
select pg_temp.eq('approved live offer applied (22.50 AED)',
  (select subtotal_fils from place_order('br_04','pickup','[{"product_id":"cat_13_item_01","qty":1}]')), 2250);
reset role;
update offers set starts_at=now()-interval '3 day', ends_at=now()-interval '1 day';
set role anon;
select pg_temp.eq('expired offer hidden from public', (select count(*) from offers), 0::bigint);
select pg_temp.eq('expired offer not in public_menu',
  (select x->>'offer_price_fils' from jsonb_array_elements((select public_menu('br_04'))->'categories') c,
          jsonb_array_elements(c->'items') x where x->>'id'='cat_13_item_01'), null::text);
reset role;

-- 9. opening hours incl. past midnight ------------------------------------------
delete from branch_hours where branch_id='br_04';
insert into branch_hours values ('br_04', 4, '16:00', '02:00');   -- Thursday 16:00 → Friday 02:00
select pg_temp.eq('Thu 23:30 Dubai open',  fb_branch_is_open('br_04', '2026-10-01 23:30+04'), true);
select pg_temp.eq('Fri 01:30 Dubai open',  fb_branch_is_open('br_04', '2026-10-02 01:30+04'), true);
select pg_temp.eq('Fri 02:30 Dubai closed', fb_branch_is_open('br_04', '2026-10-02 02:30+04'), false);
select pg_temp.eq('Thu 15:00 Dubai closed', fb_branch_is_open('br_04', '2026-10-01 15:00+04'), false);

-- 10. role changes are audited ----------------------------------------------------
select pg_temp.eq('role grants audited', (select count(*) from audit_log where table_name='staff_roles'), 5::bigint);

\echo ALL BACKEND TESTS PASSED
