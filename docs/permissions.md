# 5 — Permissions

**What you'll do:** Gate UI affordances by server-assigned roles and permissions, read permission state in code, and seed test permissions for local dev.

---

## How it works

Velora's permission system is a **frontend convenience layer** — it hides or disables UI that the user doesn't have access to. Backend Laravel policies and middleware must still enforce every access rule. Frontend checks are never a security boundary.

`PermissionService` reads the current user's roles and permissions from `Velora.auth.user` after login. Your Laravel `/auth/me` endpoint returns the arrays; Velora reads whatever strings your API provides.

## Checking in code

```dart
// Check a permission
if (Velora.permission.can('users.create')) {
  // show the create button
}

// Check a role
if (Velora.permission.hasRole('admin')) {
  // show admin settings
}
```

## Gating widgets

Use `Can` to conditionally show a subtree based on a permission, or `RoleOnly` for a role:

```dart
// Show only to users with the 'users.delete' permission
Can(
  permission: 'users.delete',
  child: IconButton(
    onPressed: controller.deleteUser,
    icon: const Icon(Icons.delete),
  ),
)

// Show only to the 'admin' role
RoleOnly(
  role: 'admin',
  child: const AdminPanel(),
)

// With a fallback when permission is absent
Can(
  permission: 'users.create',
  child: const CreateUserButton(),
  fallback: const SizedBox.shrink(),
)
```

Both widgets are reactive — they rebuild automatically if permissions change after a token refresh.

## Permission naming

Permissions follow a `resource.action` convention that matches Laravel Gate ability names:

```
users.view      users.create    users.edit      users.delete
reports.export  billing.manage  settings.write
```

You define the strings in Laravel and return them in the `/auth/me` response. There is no hardcoded permission list in the framework.

## Seeding for local dev

In mock mode, configure roles and permissions in your mock user so screens reflect real access levels while building:

```dart
// In your mock auth data source
final mockUser = VeloraUser(
  id: '1',
  name: 'Demo User',
  email: 'demo@example.com',
  roles: ['admin'],
  permissions: [
    'users.view',
    'users.create',
    'users.edit',
    'users.delete',
    'reports.export',
  ],
);
```

To test a restricted user, remove permissions from the seed and verify that `Can` widgets hide the correct affordances.

---

**Next:** [6 — Notifications →](notifications.md)
