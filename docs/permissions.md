# Permissions

Frontend permissions are UI convenience only. Backend Laravel policies/middleware must still enforce access.

`PermissionService` reads the authenticated user's roles and permissions from `Velora.auth.user`.

```dart
Velora.permission.can('users.create');
Can(permission: 'users.create', child: CreateButton());
```

Use permission checks to hide or disable UI affordances, not to protect data. Mock/demo sessions may seed permissions for local testing, but production authorization belongs to Laravel.
