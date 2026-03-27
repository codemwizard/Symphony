-- TEST 8: Table created via LIKE without RLS
-- Purpose: Catches implicit tenant_id inheritance without RLS block
-- Expected: FAIL — LIKE_WITHOUT_RLS

CREATE TABLE public.new_table (LIKE public.old_table INCLUDING ALL);
