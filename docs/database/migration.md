# SplitLedger Database Migrations

## Overview

SplitLedger uses **PostgreSQL** as the authoritative source of truth for application and financial data.

Database schema changes are managed through **Supabase migrations**.

The migration files are stored in:

```text
supabase/migrations/
```

The database schema should **not** be maintained by manually creating or modifying tables through the Supabase dashboard.

Instead, every schema change should be represented by a migration and committed to Git.

---

## Why We Use Migrations

A migration is a versioned change to the database schema.

For example:

```text
Migration 001
    ↓
Create users, groups, and memberships

Migration 002
    ↓
Create expenses

Migration 003
    ↓
Create settlements

Migration 004
    ↓
Add an index

Migration 005
    ↓
Add a constraint
```

This gives the project a reproducible database history.

A new developer should be able to clone the repository and reconstruct the development database using the migration history.

This is preferable to relying on undocumented manual changes made through the Supabase dashboard.

---

## Migration Directory

The migration directory is:

```text
supabase/
└── migrations/
```

The directory contains SQL migration files.

For example:

```text
supabase/
└── migrations/
    ├── 001_initial_schema.sql
    ├── 002_add_some_feature.sql
    └── 003_add_some_index.sql
```

Supabase normally generates timestamp-based migration filenames.

If the Supabase CLI has generated a filename such as:

```text
20260810210000_initial_schema.sql
```

that filename should be kept.

The important part is that migrations remain **ordered and version-controlled**.

---

# Initial Migration

The first SplitLedger migration establishes the foundational database schema.

It creates:

* `users`
* `groups`
* `group_members`
* `expenses`
* `expense_splits`
* `settlements`

It also establishes:

* Primary keys
* Foreign keys
* Unique constraints
* Check constraints
* Indexes
* Timestamps
* Automatic `updated_at` handling
* Row Level Security

---

# Database Relationships

The initial schema represents the following relationships:

```text
User
 │
 ├────────── Groups
 │
 └────────── Group Members ────────── Groups
                                      │
                                      │
                                      ▼
                                   Expenses
                                      │
                                      ▼
                                Expense Splits
                                      │
                                      ▼
                                    Users
```

Settlements are associated with a group and two users:

```text
Group
 │
 └────────── Settlement
                 │
                 ├──── from_user
                 │
                 └──── to_user
```

---

# Creating a Migration

A new database change should be created as a **new migration**.

> Do not modify an old migration that has already been applied to a shared or persistent database.

The general workflow is:

```text
Identify schema change
        ↓
Create new migration
        ↓
Write SQL
        ↓
Apply migration locally
        ↓
Verify database
        ↓
Test constraints
        ↓
Commit migration to Git
```

The exact Supabase CLI command should be checked against the current Supabase CLI documentation.

---

# Applying Migrations Locally

The local Supabase development environment should be running before applying or testing migrations.

The local database can then be updated using the current Supabase CLI migration workflow.

The important principle is:

```text
Migration files
       ↓
Supabase CLI
       ↓
Local PostgreSQL database
```

The local database should reflect the migration history rather than being manually modified.

---

# Development Database

The local development database is used to test schema changes before they are applied to a shared or hosted environment.

A typical development workflow is:

```text
Change schema
      ↓
Create migration
      ↓
Apply migration locally
      ↓
Inspect tables
      ↓
Test constraints
      ↓
Run application tests
```

If a migration fails, fix the migration before moving forward.

---

# Current Schema

Migration 001 creates the following tables.

## `users`

Stores the SplitLedger application user.

### Important fields

* `id`
* `firebase_uid`
* `name`
* `email`
* `avatar_url`
* `created_at`
* `updated_at`

`firebase_uid` connects the application user to Firebase Authentication.

---

## `groups`

Stores SplitLedger groups.

### Important fields

* `id`
* `name`
* `created_by`
* `created_at`
* `updated_at`

`created_by` references `users.id`.

---

## `group_members`

Represents the many-to-many relationship between users and groups.

### Important fields

* `group_id`
* `user_id`
* `role`
* `joined_at`

The combination of:

```text
group_id + user_id
```

must be unique.

---

## `expenses`

Stores expenses created inside groups.

### Important fields

* `id`
* `group_id`
* `paid_by`
* `description`
* `amount`
* `expense_date`
* `created_at`
* `updated_at`

Monetary values use:

```text
NUMERIC(12,2)
```

instead of floating-point types.

---

## `expense_splits`

Stores how an expense is divided between users.

### Important fields

* `expense_id`
* `user_id`
* `amount`

The combination of:

```text
expense_id + user_id
```

must be unique.

---

## `settlements`

Stores completed settlements between group members.

### Important fields

* `id`
* `group_id`
* `from_user`
* `to_user`
* `amount`
* `created_at`

A settlement must satisfy:

```text
from_user != to_user
amount > 0
```

---

# Foreign Key Strategy

Foreign keys are used to protect relationships between tables.

Financial records should not be accidentally removed through cascading deletes.

The initial strategy is:

| Relationship                | Delete Strategy |
| --------------------------- | --------------- |
| `users → groups`            | `RESTRICT`      |
| `groups → expenses`         | `RESTRICT`      |
| `groups → settlements`      | `RESTRICT`      |
| `expenses → expense_splits` | `CASCADE`       |
| `groups → group_members`    | `CASCADE`       |

Group membership uses:

```text
groups → group_members
CASCADE
```

because membership is dependent on the existence of the group.

User deletion is restricted where financial or membership history depends on the user.

The exact deletion strategy may be refined as the application requirements evolve.

---

# Database Constraints

The database enforces structural integrity wherever practical.

Examples include:

* `firebase_uid` must be unique
* `group_id + user_id` must be unique
* `expense_id + user_id` must be unique
* Expense amount must be greater than `0`
* Split amount must be greater than `0`
* Settlement amount must be greater than `0`
* `from_user != to_user`

Foreign keys ensure that referenced users, groups, and expenses exist.

---

# Business Rules vs Database Rules

Not every business rule belongs in a database constraint.

The database should enforce structural rules such as:

* A split must reference an existing expense.
* A group member must reference an existing user.
* An amount must be positive.
* A user cannot appear twice in the same expense split.

The backend should enforce business rules such as:

* The expense payer must belong to the group.
* All expense participants must belong to the group.
* The sum of the splits must equal the expense amount.
* A settlement must not exceed the user's outstanding debt.

This keeps the database responsible for **data integrity** while keeping domain logic in the backend.

---

# Transactions

Financial operations that modify multiple tables must use **database transactions**.

For example, creating an expense may involve:

```sql
BEGIN;

Create expense
Create expense split 1
Create expense split 2
Create expense split 3

COMMIT;
```

If one operation fails:

```sql
ROLLBACK;
```

This prevents partially created financial records.

The application should never leave an expense without its required splits because one part of the operation failed.

---

# Indexes

Indexes are created based on expected query patterns.

The initial schema includes indexes for common queries such as:

* Find groups created by a user
* Find groups belonging to a user
* Find members of a group
* Find expenses in a group
* Find expenses paid by a user
* Find splits for an expense
* Find splits involving a user
* Find settlements in a group
* Find settlements sent by a user
* Find settlements received by a user

Indexes should **not** be added to every column.

Additional indexes should be introduced when query patterns or performance measurements justify them.

---

# Row Level Security

Row Level Security (RLS) is enabled on the core application tables.

Currently:

```text
RLS = enabled
Policies = not yet implemented
```

RLS policies will be designed and tested separately.

The goal is to ensure that a user cannot access another group's data merely by knowing its ID.

Conceptually:

```text
Request
   ↓
PostgreSQL
   ↓
Does this user have access?
   ↓
YES → allow
NO  → reject / hide row
```

The detailed policies belong to the next database security milestone.

---

# Source of Truth

PostgreSQL is the **authoritative source of truth** for financial data.

```text
Flutter local data
        ≠
Authoritative ledger
```

Firebase Authentication is responsible for identity, not financial records.

```text
Firebase Authentication
        ≠
Financial ledger
```

The Node.js backend contains application and business logic, but PostgreSQL remains the permanent storage layer.

```text
Node.js
   ↓
Business logic
   ↓
PostgreSQL
   ↓
Authoritative data
```

---

# Database Change Workflow

All future database changes should follow this process:

```text
1. Identify the required schema change
                ↓
2. Create a new migration
                ↓
3. Write the SQL
                ↓
4. Apply it locally
                ↓
5. Inspect the resulting schema
                ↓
6. Test valid data
                ↓
7. Test invalid data
                ↓
8. Verify constraints and indexes
                ↓
9. Update database documentation
                ↓
10. Commit the migration
```

Database changes should be reproducible from the migration files.

---

# Current Migration Status

## Migration 001 — Initial Schema

### Status

**Created**

### Creates

* `users`
* `groups`
* `group_members`
* `expenses`
* `expense_splits`
* `settlements`

### Also includes

* Primary keys
* Foreign keys
* Unique constraints
* Check constraints
* Indexes
* Timestamps
* `updated_at` triggers
* Row Level Security enabled
