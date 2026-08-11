# RLS Test Cases

These test cases define the expected authorization behavior before PostgreSQL RLS policies are implemented.

## Test Users

For the examples below:

* **Raj** is a member of `Goa Trip`.
* **Amit** is a member/owner of `Office Trip`.
* Raj is not a member of `Office Trip`.

---

## Scenario 1 — Member Can Access Their Group

### Given

```text
Raj ∈ Goa Trip
```

### Expected

Raj can:

```text
✅ View Goa Trip
✅ View Goa Trip members
✅ View Goa Trip expenses
✅ View Goa Trip expense splits
✅ View Goa Trip settlements
```

---

## Scenario 2 — Member Cannot Access Another Group

### Given

```text
Raj ∉ Office Trip
```

### Expected

Raj cannot:

```text
❌ View Office Trip
❌ View Office Trip members
❌ View Office Trip expenses
❌ View Office Trip expense splits
❌ View Office Trip settlements
```

---

## Scenario 3 — Unauthorized Expense Creation

### Given

Raj is not a member of `Office Trip`.

### Action

Raj attempts to create:

```text
Expense
group_id = Office Trip
```

### Expected

```text
❌ Denied
```

The request must not allow Raj to create financial data inside an unauthorized group.

---

## Scenario 4 — Unauthorized Expense Modification

### Given

An expense belongs to `Office Trip`.

Raj is not a member of `Office Trip`.

### Action

Raj attempts to modify the expense.

### Expected

```text
❌ Denied
```

Raj must not be able to update an expense belonging to an unauthorized group.

---

## Scenario 5 — Unauthorized Expense Deletion

### Given

An expense belongs to `Office Trip`.

Raj is not a member of `Office Trip`.

### Action

Raj attempts to delete the expense.

### Expected

```text
❌ Denied
```

---

## Scenario 6 — Unauthorized Expense Split Access

### Given

An expense belongs to `Office Trip`.

Raj is not a member of `Office Trip`.

### Action

Raj attempts to access one of the expense's splits.

### Expected

```text
❌ Denied
```

Authorization must follow:

```text
Expense Split
    ↓
Expense
    ↓
Group
    ↓
Membership
```

---

## Scenario 7 — Unauthorized Settlement Access

### Given

A settlement belongs to `Office Trip`.

Raj is not a member of `Office Trip`.

### Action

Raj attempts to view the settlement.

### Expected

```text
❌ Denied
```

---

## Scenario 8 — Authorized Expense Creation

### Given

```text
Raj ∈ Goa Trip
```

### Action

Raj creates an expense belonging to `Goa Trip`.

### Expected

```text
✅ Allowed
```

The expense must remain associated with an authorized group.

---

## Scenario 9 — Prevent Moving Data Across Groups

### Given

Raj is a member of `Goa Trip` but not `Office Trip`.

An expense belongs to `Goa Trip`.

### Action

Raj attempts to update:

```text
group_id = Office Trip
```

### Expected

```text
❌ Denied
```

An update must not allow a user to move an existing financial record into a group they are not authorized to access.

---

## Scenario 10 — Unauthorized Membership Creation

### Given

Raj is not a member of `Office Trip`.

### Action

Raj attempts to create a `group_members` record that gives Raj membership in `Office Trip`, bypassing the intended invitation/authorization flow.

### Expected

```text
❌ Denied
```

A user must not be able to grant themselves unauthorized access simply by inserting a membership record.

---

## Scenario 11 — Member Cannot Modify Group

### Given

Raj is a `member` of `Goa Trip`.

### Action

Raj attempts to modify group-level settings.

### Expected

```text
❌ Denied
```

Only the `owner` may modify group-level settings.

---

## Scenario 12 — Owner Can Modify Group

### Given

Amit is the `owner` of `Office Trip`.

### Action

Amit modifies permitted group settings.

### Expected

```text
✅ Allowed
```

---

## Scenario 13 — Member Cannot Remove Another Member

### Given

Raj is a `member` of `Goa Trip`.

### Action

Raj attempts to remove another member.

### Expected

```text
❌ Denied
```

---

## Scenario 14 — Owner Can Manage Members

### Given

Amit is the `owner` of `Office Trip`.

### Action

Amit performs an authorized membership-management operation.

### Expected

```text
✅ Allowed
```

The operation must still follow the intended invitation and membership rules.

---

## Scenario 15 — User Cannot Access Another User's Private Profile

### Given

Raj and Amit are separate users.

### Action

Raj attempts to access Amit's private profile information.

### Expected

```text
❌ Denied
```

A user's authentication does not grant access to every user's profile.

---

# Authorization Invariants

The following invariants must always hold.

### Group isolation

```text
User not authorized for Group
        ↓
No access to Group
```

### Financial-data isolation

```text
User not authorized for Group
        ↓
No access to that group's
expenses, splits, or settlements
```

### Membership protection

```text
User cannot grant themselves
unauthorized group membership
```

### Cross-group protection

```text
Authorized for Group A
        ≠
Authorized for Group B
```

Access to one group must never imply access to another group.

### Role protection

```text
member
  ≠
owner
```

A member must not gain owner privileges by modifying their own membership record or role.

---

# Final Security Requirement

The database must enforce the following principle:

> An authenticated user may access a group-scoped record only when the user has appropriate membership or authorization for the group associated with that record.

These test cases will be used to validate the RLS policies after implementation.


## Authentication Identity Tests

### Test AUTH-001 — Firebase identity resolution

Given an authenticated Firebase user:

- Firebase UID must be available in the Firebase JWT.
- Supabase must accept the Firebase JWT.
- The request must be treated as an authenticated request.
- PostgreSQL `auth.uid()` must resolve to the expected identity.

Expected result:

PASS

---

### Test AUTH-002 — Unknown Firebase user

Given a Firebase user who does not have a corresponding
SplitLedger `users` record:

The user must not be treated as a valid SplitLedger application
user.

Expected result:

DENIED

---

### Test AUTH-003 — User identity spoofing

User A must not be able to submit User B's application user ID
and perform an operation as User B.

Expected result:

DENIED
## Expense Ownership Tests

### Test EXP-001 — Creator can edit

The user who created an expense can edit it.

Expected result:

ALLOWED

---

### Test EXP-002 — Creator can delete

The user who created an expense can delete it.

Expected result:

ALLOWED

---

### Test EXP-003 — Another member cannot edit

A different group member cannot edit another user's expense
unless explicitly authorized by the application's authorization
rules.

Expected result:

DENIED

---

### Test EXP-004 — Payer is not creator

A user can create an expense where another group member is
the payer.

Example:

created_by = Raj
paid_by = Amit

Expected result:

ALLOWED