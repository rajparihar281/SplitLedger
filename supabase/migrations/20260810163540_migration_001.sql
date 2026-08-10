-- ============================================================
-- SplitLedger - Initial Database Schema
-- Migration 001
--
-- PostgreSQL is the authoritative source of truth for:
-- - users
-- - groups
-- - group membership
-- - expenses
-- - expense splits
-- - settlements
-- ============================================================


-- ============================================================
-- Extensions
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
-- Helper function: automatically update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


-- ============================================================
-- Users
-- ============================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Firebase Authentication UID
    firebase_uid TEXT NOT NULL UNIQUE,

    name TEXT NOT NULL,

    email TEXT NOT NULL,

    avatar_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- Email uniqueness should not depend on letter casing.
-- Example:
-- Raj@example.com
-- raj@example.com
-- should be treated as the same email.
CREATE UNIQUE INDEX users_email_lower_idx
    ON users (LOWER(email));


CREATE TRIGGER users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- ============================================================
-- Groups
-- ============================================================

CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,

    created_by UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT groups_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE RESTRICT
);


CREATE INDEX groups_created_by_idx
    ON groups (created_by);


CREATE TRIGGER groups_updated_at
BEFORE UPDATE ON groups
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- ============================================================
-- Group Members
-- ============================================================

CREATE TABLE group_members (
    group_id UUID NOT NULL,

    user_id UUID NOT NULL,

    role TEXT NOT NULL DEFAULT 'member',

    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (group_id, user_id),

    CONSTRAINT group_members_group_fkey
        FOREIGN KEY (group_id)
        REFERENCES groups(id)
        ON DELETE CASCADE,

    CONSTRAINT group_members_user_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT group_members_role_check
        CHECK (role IN ('owner', 'member'))
);


CREATE INDEX group_members_user_id_idx
    ON group_members (user_id);


-- ============================================================
-- Expenses
-- ============================================================

CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    group_id UUID NOT NULL,

    paid_by UUID NOT NULL,

    description TEXT NOT NULL,

    amount NUMERIC(12, 2) NOT NULL,

    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT expenses_amount_positive
        CHECK (amount > 0),

    CONSTRAINT expenses_group_fkey
        FOREIGN KEY (group_id)
        REFERENCES groups(id)
        ON DELETE RESTRICT,

    CONSTRAINT expenses_paid_by_fkey
        FOREIGN KEY (paid_by)
        REFERENCES users(id)
        ON DELETE RESTRICT
);


CREATE INDEX expenses_group_id_idx
    ON expenses (group_id);


CREATE INDEX expenses_paid_by_idx
    ON expenses (paid_by);


CREATE TRIGGER expenses_updated_at
BEFORE UPDATE ON expenses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- ============================================================
-- Expense Splits
-- ============================================================

CREATE TABLE expense_splits (
    expense_id UUID NOT NULL,

    user_id UUID NOT NULL,

    amount NUMERIC(12, 2) NOT NULL,

    PRIMARY KEY (expense_id, user_id),

    CONSTRAINT expense_splits_amount_positive
        CHECK (amount > 0),

    CONSTRAINT expense_splits_expense_fkey
        FOREIGN KEY (expense_id)
        REFERENCES expenses(id)
        ON DELETE CASCADE,

    CONSTRAINT expense_splits_user_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
);


CREATE INDEX expense_splits_user_id_idx
    ON expense_splits (user_id);


-- ============================================================
-- Settlements
-- ============================================================

CREATE TABLE settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    group_id UUID NOT NULL,

    from_user UUID NOT NULL,

    to_user UUID NOT NULL,

    amount NUMERIC(12, 2) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT settlements_amount_positive
        CHECK (amount > 0),

    CONSTRAINT settlements_users_different
        CHECK (from_user <> to_user),

    CONSTRAINT settlements_group_fkey
        FOREIGN KEY (group_id)
        REFERENCES groups(id)
        ON DELETE RESTRICT,

    CONSTRAINT settlements_from_user_fkey
        FOREIGN KEY (from_user)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT settlements_to_user_fkey
        FOREIGN KEY (to_user)
        REFERENCES users(id)
        ON DELETE RESTRICT
);


CREATE INDEX settlements_group_id_idx
    ON settlements (group_id);


CREATE INDEX settlements_from_user_idx
    ON settlements (from_user);


CREATE INDEX settlements_to_user_idx
    ON settlements (to_user);


-- ============================================================
-- Row Level Security
--
-- Policies will be added in the next milestone.
-- Enabling RLS now ensures that tables are not accidentally
-- exposed through Supabase client access before policies exist.
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;