Velora Framework — AI Agent Implementation Blueprint

0. Mission

Build Velora, a Laravel-style, batteries-included Flutter frontend framework for building production-ready apps fast across:

- Android
- iOS
- Web

Velora should make Flutter feel like Laravel:

- Convention over configuration
- Simple facade-style syntax
- One default way to build common apps
- Laravel REST API first
- Sanctum token authentication first
- Role + permission aware frontend
- No Firebase
- No Supabase
- AI-ready project structure
- CLI scaffolding for fast app generation

The goal is not to replace Flutter. The goal is to build a productive framework layer on top of Flutter.

---

1. Framework Name

Name

Velora

Tagline

Laravel-like productivity for Flutter apps.

Internal Package Names

Use these package names:

velora
velora_cli
velora_starter

Optional future packages:

velora_ui
velora_auth
velora_http
velora_storage
velora_permissions
velora_ai

For MVP, keep most runtime code inside one main package named "velora". Do not over-split too early.

---

2. Product Philosophy

Velora must follow these principles:

2.1 Convention Over Configuration

A developer should be able to create a module without making many architectural decisions.

Example:

velora make:module products --crud

This should generate:

lib/app/modules/products/
  products_binding.dart
  products_controller.dart
  products_service.dart
  products_model.dart
  products_routes.dart
  views/
    products_index_page.dart
    products_create_page.dart
    products_edit_page.dart
    products_show_page.dart

2.2 Facade-Style API

Common operations should be accessible through one consistent API.

Example:

Velora.api.get('/users');
Velora.auth.login({'email': email, 'password': password});
Velora.auth.logout();
Velora.auth.user;
Velora.storage.set('token', token);
Velora.nav.to('/dashboard');
Velora.toast.success('Saved successfully');
Velora.permission.can('users.create');

The syntax should feel simple like Laravel facades.

2.3 Batteries Included

The starter kit must include:

- Routing
- State management
- Dependency injection
- API client
- Auth system
- Token storage
- Role and permission helper
- Form validation
- Toast/snackbar helper
- Dialog helper
- Loading overlay
- Error handling
- API response normalization
- Pagination helper
- CRUD scaffolding
- Theme system
- Responsive layout helpers
- AI documentation folder
- Example Laravel Sanctum API integration

2.4 Laravel REST API First

The first backend target is:

- Laravel REST API
- Laravel Sanctum personal access tokens
- Spatie-style roles and permissions
- Resource-based API responses

No Firebase.
No Supabase.
No GraphQL for MVP.

---

3. Recommended Internal Stack

Flutter Runtime

Use Flutter stable.

Core Runtime Dependencies

Use these internally:

dependencies:
  flutter:
    sdk: flutter

  get: latest
  dio: latest
  shared_preferences: latest
  flutter_secure_storage: latest
  intl: latest
  logger: latest
  equatable: latest

Optional Later Dependencies

Do not add these in MVP unless needed:

connectivity_plus:
cached_network_image:
image_picker:
file_picker:
url_launcher:
flutter_local_notifications:

MVP should stay focused.

---

4. High-Level Architecture

Velora consists of two main layers:

1. Runtime framework package
2. CLI scaffolding tool

4.1 Runtime Package

The runtime package provides the app-facing API:

Velora.api
Velora.auth
Velora.storage
Velora.nav
Velora.toast
Velora.dialog
Velora.loader
Velora.permission
Velora.config

4.2 CLI Tool

The CLI generates project structure, modules, services, models, forms, and CRUD screens.

Example commands:

velora new my_app
velora make:module users --crud
velora make:service billing
velora make:model product
velora make:screen dashboard
velora make:form login
velora make:resource user
velora doctor

---

5. Monorepo Structure

Create the repo like this:

velora/
  README.md
  LICENSE
  CHANGELOG.md
  AGENTS.md
  analysis_options.yaml

  packages/
    velora/
      pubspec.yaml
      lib/
        velora.dart
        src/
          core/
          config/
          http/
          auth/
          storage/
          routing/
          ui/
          permissions/
          validation/
          support/
          ai/

    velora_cli/
      pubspec.yaml
      bin/
        velora.dart
      lib/
        src/
          commands/
          generators/
          templates/
          utils/

  examples/
    velora_starter/
      pubspec.yaml
      lib/
        main.dart
        app/
        config/
        routes/
        resources/

  docs/
    getting-started.md
    architecture.md
    api-client.md
    auth.md
    permissions.md
    scaffolding.md
    ai-ready.md

  .ai/
    project-context.md
    architecture-map.md
    conventions.md
    agent-tasks.md
    prompts/
      build-module.md
      debug-api.md
      refactor-feature.md

---

6. Runtime Package Design

6.1 Public Entry File

Create:

packages/velora/lib/velora.dart

Export all public APIs from here.

Example:

library velora;

export 'src/core/velora_app.dart';
export 'src/core/velora_facade.dart';
export 'src/config/velora_config.dart';
export 'src/http/velora_api.dart';
export 'src/auth/velora_auth.dart';
export 'src/storage/velora_storage.dart';
export 'src/routing/velora_nav.dart';
export 'src/ui/velora_toast.dart';
export 'src/ui/velora_dialog.dart';
export 'src/ui/velora_loader.dart';
export 'src/permissions/velora_permission.dart';
export 'src/validation/velora_validator.dart';
export 'src/support/result.dart';
export 'src/support/api_response.dart';

---

7. App Bootstrap API

The developer should start an app like this:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Velora.boot(
    config: VeloraConfig(
      appName: 'Demo App',
      apiBaseUrl: 'https://api.example.com/api',
      auth: VeloraAuthConfig(
        loginEndpoint: '/auth/login',
        logoutEndpoint: '/auth/logout',
        meEndpoint: '/auth/me',
      ),
    ),
  );

  runApp(const App());
}

The actual app should use "GetMaterialApp" internally or expose a wrapper.

Example:

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return VeloraApp(
      title: 'Demo App',
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}

---

8. Facade API Spec

Create a static facade class:

class Velora {
  static late VeloraConfig config;

  static VeloraApi get api => Get.find<VeloraApi>();
  static VeloraAuth get auth => Get.find<VeloraAuth>();
  static VeloraStorage get storage => Get.find<VeloraStorage>();
  static VeloraNav get nav => Get.find<VeloraNav>();
  static VeloraToast get toast => Get.find<VeloraToast>();
  static VeloraDialog get dialog => Get.find<VeloraDialog>();
  static VeloraLoader get loader => Get.find<VeloraLoader>();
  static VeloraPermission get permission => Get.find<VeloraPermission>();

  static Future<void> boot({
    required VeloraConfig config,
  }) async {
    Velora.config = config;

    final storage = VeloraStorage();
    await storage.init();

    Get.put<VeloraStorage>(storage, permanent: true);
    Get.put<VeloraApi>(VeloraApi(config: config, storage: storage), permanent: true);
    Get.put<VeloraAuth>(VeloraAuth(api: Get.find(), storage: storage), permanent: true);
    Get.put<VeloraNav>(VeloraNav(), permanent: true);
    Get.put<VeloraToast>(VeloraToast(), permanent: true);
    Get.put<VeloraDialog>(VeloraDialog(), permanent: true);
    Get.put<VeloraLoader>(VeloraLoader(), permanent: true);
    Get.put<VeloraPermission>(VeloraPermission(auth: Get.find()), permanent: true);
  }
}

---

9. API Client Spec

9.1 Goal

Create a wrapper around Dio that:

- Uses base URL from config
- Automatically injects Bearer token
- Normalizes API responses
- Normalizes errors
- Supports GET, POST, PUT, PATCH, DELETE
- Supports file upload later
- Supports Laravel validation errors

9.2 Public API

await Velora.api.get('/users');
await Velora.api.post('/users', data: {});
await Velora.api.put('/users/1', data: {});
await Velora.api.patch('/users/1', data: {});
await Velora.api.delete('/users/1');

9.3 Response Shape

Create:

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, List<String>> errors;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors = const {},
    this.statusCode,
  });
}

9.4 Error Shape

Create:

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors = const {},
  });
}

9.5 Laravel Validation Handling

Laravel validation error example:

{
  "message": "The email field is required.",
  "errors": {
    "email": ["The email field is required."]
  }
}

Velora must convert that into:

ApiException(
  message: 'The email field is required.',
  statusCode: 422,
  errors: {
    'email': ['The email field is required.'],
  },
)

---

10. Auth System Spec

10.1 Backend Assumption

Laravel API returns login response like this:

{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "plain-text-sanctum-token",
    "user": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com",
      "roles": ["admin"],
      "permissions": ["users.view", "users.create"]
    }
  }
}

Velora should also support this simpler fallback response:

{
  "token": "plain-text-sanctum-token",
  "user": {}
}

10.2 Public API

await Velora.auth.login(
  email: email,
  password: password,
);

await Velora.auth.logout();

final user = Velora.auth.user;

final isLoggedIn = Velora.auth.check;

final token = await Velora.auth.token();

10.3 Auth State

Use GetX internally:

final Rxn<AuthUser> currentUser = Rxn<AuthUser>();
final RxBool isAuthenticated = false.obs;

10.4 AuthUser Model

class AuthUser {
  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final List<String> permissions;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.roles = const [],
    this.permissions = const [],
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }
}

10.5 Token Storage

Store token using secure storage where possible.

Fallback to shared preferences for web compatibility if needed.

Provide storage adapter interface:

abstract class TokenStore {
  Future<void> setToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}

---

11. Permission System Spec

Velora should make frontend permissions simple.

11.1 Public API

Velora.permission.can('users.create');
Velora.permission.cannot('users.delete');
Velora.permission.hasRole('admin');
Velora.permission.hasAnyRole(['admin', 'manager']);
Velora.permission.hasAllPermissions(['users.view', 'users.create']);

11.2 UI Helpers

Create widgets:

Can(
  permission: 'users.create',
  child: CreateUserButton(),
);

RoleOnly(
  role: 'admin',
  child: AdminPanelButton(),
);

11.3 Important Security Rule

Frontend permission checks are only for UI convenience.

Backend Laravel API must still enforce permissions.

Add this warning in docs.

---

12. Storage System Spec

12.1 Public API

await Velora.storage.set('theme', 'dark');
final theme = await Velora.storage.get<String>('theme');
await Velora.storage.remove('theme');
await Velora.storage.clear();

12.2 Storage Types

Support:

- String
- int
- double
- bool
- List<String>
- JSON string helpers

12.3 JSON Helpers

await Velora.storage.setJson('user', user.toJson());
final json = await Velora.storage.getJson('user');

---

13. Navigation System Spec

Use GetX routing internally.

13.1 Public API

Velora.nav.to('/dashboard');
Velora.nav.off('/login');
Velora.nav.offAll('/dashboard');
Velora.nav.back();

13.2 Route Convention

App routes should live here:

lib/routes/app_routes.dart
lib/routes/app_pages.dart

Example:

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const users = '/users';
}

Example:

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
  ];
}

---

14. UI Utility Spec

14.1 Toast

Velora.toast.success('Saved successfully');
Velora.toast.error('Something went wrong');
Velora.toast.info('Loading data');
Velora.toast.warning('Check your input');

Use Get.snackbar internally.

14.2 Dialog

final confirmed = await Velora.dialog.confirm(
  title: 'Delete user?',
  message: 'This action cannot be undone.',
);

14.3 Loader

Velora.loader.show();
Velora.loader.hide();

Also create a helper:

await Velora.loader.run(() async {
  await service.save();
});

---

15. Validation System Spec

Create a lightweight validation helper.

15.1 Public API

Velora.validator.required(value);
Velora.validator.email(value);
Velora.validator.min(value, 8);
Velora.validator.max(value, 255);
Velora.validator.confirmed(value, otherValue);

15.2 Form Error Mapping

Laravel validation errors should be mappable into form fields.

Example:

controller.errors['email']

Create base form controller:

abstract class VeloraFormController extends GetxController {
  final RxMap<String, List<String>> errors = <String, List<String>>{}.obs;

  void setErrors(Map<String, List<String>> newErrors) {
    errors.assignAll(newErrors);
  }

  String? firstError(String field) {
    return errors[field]?.first;
  }

  void clearErrors() {
    errors.clear();
  }
}

---

16. Base Controller Spec

Create a base controller for all modules.

abstract class VeloraController extends GetxController {
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  Future<T?> run<T>(
    Future<T> Function() task, {
    bool showLoader = false,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      loading.value = true;

      if (showLoader) {
        Velora.loader.show();
      }

      final result = await task();

      if (successMessage != null) {
        Velora.toast.success(successMessage);
      }

      return result;
    } catch (e) {
      final message = errorMessage ?? e.toString();
      error.value = message;
      Velora.toast.error(message);
      return null;
    } finally {
      loading.value = false;

      if (showLoader) {
        Velora.loader.hide();
      }
    }
  }
}

---

17. Module Convention

Each feature module must follow this structure:

lib/app/modules/{module}/
  {module}_binding.dart
  {module}_controller.dart
  {module}_service.dart
  {module}_model.dart
  {module}_routes.dart
  views/
    {module}_index_page.dart
    {module}_show_page.dart
    {module}_create_page.dart
    {module}_edit_page.dart

Example:

lib/app/modules/users/
  users_binding.dart
  users_controller.dart
  users_service.dart
  user_model.dart
  users_routes.dart
  views/
    users_index_page.dart
    user_show_page.dart
    user_create_page.dart
    user_edit_page.dart

---

18. CRUD Service Convention

Generated service should look like:

class UsersService {
  Future<ApiResponse<List<UserModel>>> index() {
    return Velora.api.get('/users');
  }

  Future<ApiResponse<UserModel>> show(int id) {
    return Velora.api.get('/users/$id');
  }

  Future<ApiResponse<UserModel>> store(Map<String, dynamic> data) {
    return Velora.api.post('/users', data: data);
  }

  Future<ApiResponse<UserModel>> update(int id, Map<String, dynamic> data) {
    return Velora.api.put('/users/$id', data: data);
  }

  Future<ApiResponse<void>> destroy(int id) {
    return Velora.api.delete('/users/$id');
  }
}

---

19. Pagination Spec

Laravel pagination response example:

{
  "data": [],
  "links": {},
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 75
  }
}

Create:

class PaginatedData<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

Generated controllers should support:

await controller.fetch();
await controller.loadMore();
await controller.refreshList();

---

20. Theme System Spec

Create a default professional theme.

Files:

lib/resources/theme/app_theme.dart
lib/resources/theme/app_colors.dart
lib/resources/theme/app_spacing.dart
lib/resources/theme/app_radius.dart
lib/resources/theme/app_typography.dart

Expose:

VeloraTheme.light()
VeloraTheme.dark()

Starter app must include:

- Material 3 theme
- Light mode
- Dark mode
- Common spacing tokens
- Button style
- Input style
- Card style
- AppBar style

---

21. Responsive Layout Spec

Create simple helpers:

context.isMobile
context.isTablet
context.isDesktop
context.screenWidth
context.screenHeight

Create:

VeloraResponsive(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
);

MVP must support responsive dashboard layout for web and mobile.

---

22. AI-Ready Requirements

Velora must be AI-ready out of the box.

Create this folder in generated apps:

.ai/
  project-context.md
  architecture.md
  conventions.md
  api-contract.md
  module-map.json
  agent-rules.md
  tasks.md

22.1 project-context.md

Must explain:

- App name
- Backend base URL
- Auth method
- Folder structure
- State management approach
- Routing approach
- API response convention
- Module convention

22.2 agent-rules.md

Must include:

# AI Agent Rules

1. Follow Velora module conventions.
2. Do not introduce Firebase or Supabase.
3. Use Velora.api for HTTP.
4. Use Velora.auth for auth.
5. Use Velora.permission for permission checks.
6. Use GetX only through Velora conventions unless modifying framework internals.
7. Keep screens thin.
8. Put business logic in services/controllers.
9. Keep API models serializable.
10. Update `.ai/module-map.json` when adding modules.

22.3 module-map.json

Example:

{
  "modules": [
    {
      "name": "auth",
      "path": "lib/app/modules/auth",
      "routes": ["/login"],
      "api": ["/auth/login", "/auth/logout", "/auth/me"]
    },
    {
      "name": "users",
      "path": "lib/app/modules/users",
      "routes": ["/users", "/users/create", "/users/:id"],
      "api": ["/users"]
    }
  ]
}

---

23. CLI Tool Spec

23.1 CLI Name

velora

23.2 Commands

Create Project

velora new my_app

Must generate:

my_app/
  lib/
    main.dart
    app/
    config/
    routes/
    resources/
  .ai/
  pubspec.yaml
  README.md

Make Module

velora make:module users

Generates module files.

Make CRUD Module

velora make:module users --crud

Generates:

- index page
- show page
- create page
- edit page
- model
- service
- controller
- binding
- routes

Make Auth

velora make:auth --sanctum

Generates:

lib/app/modules/auth/
  auth_binding.dart
  auth_controller.dart
  auth_service.dart
  views/
    login_page.dart

Also generates:

lib/app/modules/dashboard/

Make Service

velora make:service payments

Make Model

velora make:model product

Make Screen

velora make:screen reports

Doctor

velora doctor

Checks:

- Flutter installed
- Dart installed
- pub get works
- Android/iOS/web enabled
- Required folders exist
- ".ai" folder exists
- Velora config exists

---

24. Starter App Requirements

The generated starter app must include:

1. Splash page
2. Login page
3. Dashboard page
4. Protected route example
5. Role-gated menu example
6. Permission-gated button example
7. Users CRUD example
8. API error handling example
9. Laravel validation error example
10. Responsive layout 

---
25. Starter App Folder Structure

lib/
  main.dart

  config/
    app_config.dart
    api_config.dart
    auth_config.dart

  routes/
    app_routes.dart
    app_pages.dart

  app/
    modules/
      splash/
        splash_binding.dart
        splash_controller.dart
        splash_page.dart

      auth/
        auth_binding.dart
        auth_controller.dart
        auth_service.dart
        views/
          login_page.dart

      dashboard/
        dashboard_binding.dart
        dashboard_controller.dart
        dashboard_page.dart

      users/
        users_binding.dart
        users_controller.dart
        users_service.dart
        user_model.dart
        views/
          users_index_page.dart
          user_create_page.dart
          user_edit_page.dart
          user_show_page.dart

  resources/
    theme/
      app_theme.dart
      app_colors.dart
      app_spacing.dart
      app_radius.dart
      app_typography.dart

    widgets/
      app_button.dart
      app_text_field.dart
      app_card.dart
      app_loader.dart
      permission_button.dart

26. Backend API Contract for MVP

Assume Laravel API has these endpoints:

POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me

GET    /api/users
POST   /api/users
GET    /api/users/{id}
PUT    /api/users/{id}
DELETE /api/users/{id}

26.1 Login Request

{
  "email": "admin@example.com",
  "password": "password"
}

26.2 Login Response

{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "SANCTUM_TOKEN",
    "user": {
      "id": 1,
      "name": "Admin",
      "email": "admin@example.com",
      "roles": ["admin"],
      "permissions": [
        "users.view",
        "users.create",
        "users.update",
        "users.delete"
      ]
    }
  }
}

26.3 Me Response

{
  "success": true,
  "data": {
    "id": 1,
    "name": "Admin",
    "email": "admin@example.com",
    "roles": ["admin"],
    "permissions": [
      "users.view",
      "users.create"
    ]
  }
}

27. Generated Code Style Rules

The AI agent must follow these rules:

27.1 No Business Logic in Widgets

Bad:

onPressed: () async {
  final res = await Dio().post(...);
}

Good:

onPressed: controller.login;

27.2 Controllers Manage UI State

Controllers handle:

loading

selected item

form state

calling services

handling errors

27.3 Services Call APIs

Services handle:

HTTP calls

response parsing

endpoint paths

27.4 Models Parse Data

Models handle:

fromJson

toJson

27.5 Views Only Render UI

Views should not know Dio, tokens, or Laravel details.

28. MVP Build Tasks for AI Agent

The AI agent must implement in this exact order.

Phase 1 — Repo Setup

Create monorepo folder structure.

Create root README.

Create root AGENTS.md.

Create packages/velora.

Create packages/velora_cli.

Create examples/velora_starter.

Phase 2 — Runtime Core

Implement VeloraConfig.

Implement Velora.boot.

Implement service registration with GetX.

Implement VeloraApp wrapper.

Implement facade getters.

Phase 3 — Storage

Implement VeloraStorage.

Add set, get, remove, clear.

Add token helpers.

Add JSON helpers.

Phase 4 — API

Implement VeloraApi.

Configure Dio.

Add Authorization header interceptor.

Add error normalization.

Add Laravel validation error parsing.

Add methods: get, post, put, patch, delete.

Phase 5 — Auth

Implement AuthUser.

Implement VeloraAuth.

Add login.

Add logout.

Add me.

Persist token.

Persist user.

Restore session on boot.

Phase 6 — Permissions

Implement permission facade.

Implement role helpers.

Implement Can widget.

Implement RoleOnly widget.

Phase 7 — UI Utilities

Implement toast helper.

Implement dialog helper.

Implement loader helper.

Implement base controller.

Implement form controller.

Phase 8 — Starter App

Create splash page.

Create login page.

Create dashboard page.

Create users CRUD module.

Add protected route behavior.

Add role/permission UI examples.

Add responsive dashboard.

Phase 9 — CLI

Implement velora new.

Implement velora make:module.

Implement velora make:module --crud.

Implement velora make:auth --sanctum.

Implement velora doctor.

Add templates.

Add generated .ai folder.

Phase 10 — Documentation

Write getting started guide.

Write auth guide.

Write API guide.

Write permissions guide.

Write scaffolding guide.

Write AI-ready guide.

29. Acceptance Criteria

The AI agent is done only when all criteria pass.

29.1 Framework Runtime

Must be able to write:

await Velora.boot(config: config);
Velora.toast.success('Hello');
await Velora.storage.set('x', 'y');
await Velora.api.get('/health');

29.2 Auth

Must support:

await Velora.auth.login({'email': email, 'password': password});
Velora.auth.check;
Velora.auth.user;
await Velora.auth.logout();

29.3 Permission

Must support:

Velora.permission.can('users.create');
Velora.permission.hasRole('admin');

29.4 Starter App

Must run on:

flutter run -d chrome
flutter run -d android

iOS should be supported structurally, even if the agent cannot test it locally.

29.5 CLI

These must work:

dart run velora_cli new demo_app
dart run velora_cli make:module products --crud
dart run velora_cli make:auth --sanctum
dart run velora_cli doctor

29.6 AI Readiness

Generated app must include:

.ai/project-context.md
.ai/architecture.md
.ai/conventions.md
.ai/api-contract.md
.ai/module-map.json
.ai/agent-rules.md
.ai/tasks.md

30. First Demo Goal

The first demo should show this workflow:

velora new admin_panel
cd admin_panel
velora make:auth --sanctum
velora make:module users --crud
flutter run -d chrome

The generated app should have:

Login page

Dashboard

Users list

Create user page

Edit user page

Delete confirmation

Permission-gated buttons

Token-based API requests

Laravel validation error display

31. Non-Goals for MVP

Do not build these in MVP:

Firebase integration

Supabase integration

GraphQL

Offline sync engine

Custom database ORM

Custom state management library

Visual page builder

Payment module

Push notification module

Chat module

AI chatbot module

Keep MVP focused on Laravel REST API productivity.

32. Final Implementation Instruction to AI Agent

Build the actual codebase.

Do not only describe the architecture.

Start by creating the monorepo structure, then implement the runtime package, then implement the starter app, then implement the CLI.

Use simple, readable Dart code.

Prefer working MVP over perfect abstraction.

Keep the public developer API clean and facade-like.

Velora must feel like Laravel for Flutter frontend development.