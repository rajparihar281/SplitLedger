# Row Level Security Design

## 1. Security Principle

A user may access financial data only when that user has appropriate membership or authorization within the corresponding group.

SplitLedger uses defense in depth:

```text
Flutter
   ↓
Node.js API authorization
   ↓
PostgreSQL / Supabase RLS
```

Node.js remains the application and business-logic boundary. PostgreSQL RLS provides an additional database-level security boundary so that unauthorized access is rejected even if an application-level authorization check is accidentally missed.

---

## 2. Authentication vs Authorization

### Authentication

Authentication answers:

> Who is this user?

Supabase Auth identifies the authenticated user and provides the user's identity to the database context.

### Authorization

Authorization answers:

> What is this authenticated user allowed to access?

SplitLedger determines authorization primarily through the user's membership in a group.

The conceptual relationship is:

```text
Authenticated User
       ↓
group_members
       ↓
Group
       ↓
Group-scoped financial data
```

A user being authenticated does not automatically give them access to every group or every financial record.

---

## 3. Group Membership

For group-scoped data, PostgreSQL should determine whether the authenticated user has appropriate membership in the relevant group.

Conceptually:

```text
Does the authenticated user have an
appropriate group_members record
for this group?
```

If yes, the user may access data belonging to that group, subject to the operation and role permissions defined below.

If no, access should be denied.

---

# 4. Access Model

## Users

A user may access their own profile.

### SELECT

A user can view their own profile.

A user cannot view another user's private profile data unless an explicit authorization rule permits it.

### UPDATE

A user may update permitted fields of their own profile.

Sensitive identity or authorization fields should not be user-controlled.

### INSERT / DELETE

Ordinary users should not directly create or delete authentication/profile records through the normal application API.

User lifecycle operations should remain controlled by the authentication/backend system.

---

# 5. Groups

## SELECT

A user may view a group when they are a member of that group.

```text
User → group_members → Group
```

If the membership does not exist, the group should not be visible to the user.

## INSERT

An authenticated user may create a group.

The creator should become the initial `owner` through a controlled backend operation.

Users should not be able to create a group while assigning an arbitrary user as its owner.

## UPDATE

Only the group `owner` may modify group-level settings.

A regular `member` may view the group but cannot modify it.

## DELETE

Only the group `owner` may initiate group deletion.

Deletion should be handled carefully by the backend because a group may have related members, expenses, splits, and settlements.

---

# 6. Group Members

## SELECT

A member may view membership information for groups they belong to.

For example:

```text
Raj ∈ Goa Trip
```

means Raj may view the membership information for Goa Trip.

Raj should not be able to view the membership list of Office Trip if Raj is not a member.

## INSERT

Ordinary members cannot freely add arbitrary users to a group.

The `owner` may initiate adding a member through the intended invitation/authorization flow.

Membership creation should not provide a way for a user to grant themselves unauthorized access.

## UPDATE

Ordinary members should not be able to change their own role or another member's role.

The `owner` may manage permitted membership attributes, including role changes, through controlled backend operations.

## DELETE

The `owner` may remove members.

A member may be allowed to leave a group through a controlled application operation, but should not be able to remove other members.

---

# 7. Roles

For the MVP, SplitLedger uses two group roles:

```text
owner
member
```

The role determines what a user may do within a group after membership has been established.

| Operation                     | Owner |                            Member |
| ----------------------------- | ----: | --------------------------------: |
| View group                    |   Yes |                               Yes |
| View members                  |   Yes |                               Yes |
| Create group                  |   Yes |    Yes, when creating a new group |
| Edit group                    |   Yes |                                No |
| Add members                   |   Yes |                                No |
| Remove members                |   Yes |                                No |
| Change member roles           |   Yes |                                No |
| Add expense                   |   Yes |                               Yes |
| View expenses                 |   Yes |                               Yes |
| Edit own/authorized expense   |   Yes | Yes, subject to application rules |
| Delete own/authorized expense |   Yes | Yes, subject to application rules |
| View settlements              |   Yes |                               Yes |
| Create settlement             |   Yes |                               Yes |

The application should enforce additional business rules where necessary. RLS should ensure that operations remain limited to groups the user is authorized to access.

---

# 8. Expenses

Expenses are group-scoped financial records.

## SELECT

A user may view an expense only when the expense belongs to a group that the user is authorized to access.

Conceptually:

```text
Expense
   ↓
Group
   ↓
group_members
   ↓
Authenticated User
```

If the user is not authorized for the expense's group, the expense must not be accessible.

## INSERT

A member may create an expense for a group they are authorized to access.

The backend must ensure that the expense is associated with an authorized group.

The database security layer should prevent a user from creating an expense in an unrelated group.

## UPDATE

A user may modify an expense only when they are authorized to access its group and the operation is permitted by the application rules.

The user must not be able to move an expense into an unauthorized group.

## DELETE

A user may delete an expense only when they are authorized for its group and deletion is permitted by the application rules.

Deleting an expense must not provide a way to access or modify data belonging to another group.

---

# 9. Expense Splits

Expense splits inherit their authorization from their parent expense.

## SELECT

A user may view a split only when they are authorized to access the group containing the associated expense.

Conceptually:

```text
Expense Split
     ↓
Expense
     ↓
Group
     ↓
group_members
     ↓
User
```

## INSERT / UPDATE / DELETE

Split modifications must only be possible for expenses in groups the user is authorized to access.

A user must not be able to create or modify a split that references an expense belonging to an unauthorized group.

---

# 10. Settlements

Settlements are also group-scoped financial records.

## SELECT

A user may view a settlement only when they are authorized to access the settlement's group.

## INSERT

A member may create a settlement for a group they are authorized to access, subject to the application's settlement validation rules.

## UPDATE

A user may modify a settlement only when they are authorized for its group and the operation is allowed by the application.

## DELETE

A user may delete a settlement only when they are authorized for its group and the operation is permitted by the application.

---

# 11. PostgreSQL Authorization Chain

For group-scoped financial data, authorization follows this conceptual chain:

```text
Authenticated User
        ↓
   group_members
        ↓
   Group Membership
        ↓
      Group
        ↓
Financial Record
```

For example, when PostgreSQL evaluates:

```text
Can Raj see Expense #123?
```

the logical question is:

```text
Does Expense #123 belong to a group
where Raj has appropriate membership?
```

If the answer is no, PostgreSQL RLS should deny access.

---

# 12. RLS Concepts

RLS policies will be designed around PostgreSQL's policy mechanisms.

### `USING`

`USING` determines which existing rows are visible or targetable by a user.

It is therefore relevant when determining whether a user can:

```text
SELECT
UPDATE
DELETE
```

an existing row.

### `WITH CHECK`

`WITH CHECK` determines whether a new or modified row is allowed to exist after an operation.

It is therefore important for:

```text
INSERT
UPDATE
```

operations.

For example, an expense creation policy should not merely check that Raj is authenticated. It should ensure that the expense being created belongs to a group Raj is authorized to access.

---

# 13. Least Privilege

SplitLedger should expose only the operations that ordinary users actually need.

Not every table needs every operation.

For each table, authorization should be considered independently:

```text
users
groups
group_members
expenses
expense_splits
settlements
```

and for each operation:

```text
SELECT
INSERT
UPDATE
DELETE
```

If an operation is not required by the application, it should not be granted simply for convenience.

---

# 14. Defense in Depth

RLS is not intended to replace Node.js authorization.

The intended architecture remains:

```text
Flutter
   ↓
Node.js API
   ↓
Supabase/PostgreSQL
```

Node.js handles:

* Business rules
* Expense validation
* Settlement logic
* Idempotency
* Application authorization
* Notifications
* Real-time events
* Audit behavior

PostgreSQL RLS provides an additional database-level authorization boundary.

Therefore:

```text
Application authorization
        +
Database authorization
        =
Defense in depth
```

---

# 15. Security Goal

The most important invariant is:

> A user must never be able to access group-scoped financial data unless they have appropriate membership or authorization for that group.

This must remain true even if:

* The client sends a malicious group ID.
* A user manually modifies an API request.
* A Node.js authorization check contains a bug.
* A user attempts to reference another group's records directly.

RLS should enforce the database-level boundary independently of the client.

## Authentication Identity

SplitLedger uses Firebase Authentication as its authentication provider.

The application maintains its own `users` table in PostgreSQL.

The `users` table contains:

- `id` — internal SplitLedger UUID
- `firebase_uid` — Firebase Authentication UID

Domain tables such as `groups`, `group_members`, `expenses`,
and `settlements` reference the internal `users.id`.

The intended identity flow is:

Firebase Authentication
        ↓
Firebase UID
        ↓
Firebase JWT
        ↓
Supabase Third-Party Authentication
        ↓
PostgreSQL `auth.uid()`
        ↓
SplitLedger `users.firebase_uid`
        ↓
SplitLedger `users.id`

Before implementing RLS policies, the relationship between
Firebase UID and PostgreSQL `auth.uid()` must be verified using
an actual Firebase-authenticated request.