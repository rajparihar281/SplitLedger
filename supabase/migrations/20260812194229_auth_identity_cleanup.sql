-- ============================================================
-- SplitLedger - Supabase Auth Identity Cleanup
-- Migration 002
--
-- Firebase has been removed from the architecture.
--
-- public.users.id is now the same identity as auth.users.id.
-- ============================================================

BEGIN;


-- ============================================================
-- 1. Remove Firebase-specific identity storage
-- ============================================================

ALTER TABLE public.users
    DROP CONSTRAINT IF EXISTS users_firebase_uid_key,
    DROP COLUMN IF EXISTS firebase_uid;


-- ============================================================
-- 2. Remove the old independently-generated UUID behavior
--
-- public.users.id must now be explicitly supplied using the
-- authenticated Supabase user's auth.users.id.
-- ============================================================

ALTER TABLE public.users
    ALTER COLUMN id DROP DEFAULT;


-- ============================================================
-- 3. Enforce Supabase Auth identity
--
-- public.users.id = auth.users.id
-- ============================================================

ALTER TABLE public.users
    ADD CONSTRAINT fk_users_auth_id
    FOREIGN KEY (id)
    REFERENCES auth.users (id)
    ON DELETE CASCADE;


-- ============================================================
-- 4. Add expense creator identity
--
-- created_by = user who created the expense
-- paid_by    = user who actually paid the expense
-- ============================================================

ALTER TABLE public.expenses
    ADD COLUMN created_by UUID NOT NULL;


-- ============================================================
-- 5. Protect the created_by relationship
-- ============================================================

ALTER TABLE public.expenses
    ADD CONSTRAINT fk_expenses_created_by
    FOREIGN KEY (created_by)
    REFERENCES public.users (id)
    ON DELETE RESTRICT;


-- ============================================================
-- 6. Index created_by for authorization/query performance
-- ============================================================

CREATE INDEX expenses_created_by_idx
    ON public.expenses (created_by);


COMMIT;
