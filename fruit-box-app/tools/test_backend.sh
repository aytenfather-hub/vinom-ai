#!/usr/bin/env bash
# Creates a fresh database, applies the local Supabase shim, all migrations and
# the seed, then runs the behaviour tests. Requires a running PostgreSQL.
#   PGHOST=/tmp PGPORT=54322 PGUSER=postgres tools/test_backend.sh
set -euo pipefail
cd "$(dirname "$0")/.."
DB=fruitbox_test
python3 tools/build_seed.py >/dev/null
python3 tools/build_seed_sql.py
psql -q -d postgres -c "drop database if exists $DB" -c "create database $DB" >/dev/null
run() { psql -q -v ON_ERROR_STOP=1 -d $DB -f "$1" >/dev/null; echo "applied $1"; }
run backend/supabase/tests/00_local_supabase_shim.sql
for f in backend/supabase/migrations/*.sql; do run "$f"; done
run backend/supabase/seed.sql
psql -v ON_ERROR_STOP=1 -d $DB -f backend/supabase/tests/10_behaviour_test.sql
