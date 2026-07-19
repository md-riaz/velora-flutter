import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:velora_cli/velora_cli.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.first == 'help') {
    _printHelp();
    return;
  }

  switch (arguments.first) {
    case 'new':
      _new(arguments.skip(1).toList());
    case 'make:module':
      _makeModule(arguments.skip(1).toList());
    case 'make:auth':
      _makeAuth(arguments.skip(1).toList());
    case 'make:notifications':
      _makeNotifications(arguments.skip(1).toList());
    case 'install:push':
      _installPush(arguments.skip(1).toList());
    case 'install':
      _install(arguments.skip(1).toList());
    case 'doctor':
      _doctor();
    default:
      _fail('Unknown command: ${arguments.first}');
  }
}

void _printHelp() {
  stdout.writeln('Velora CLI');
  stdout.writeln('  velora new <name>');
  stdout.writeln('  velora make:module <name> [--crud]');
  stdout.writeln('  velora make:auth --sanctum');
  stdout.writeln('  velora make:notifications');
  stdout.writeln('  velora install:push --fcm');
  stdout.writeln('  velora install:push --local');
  stdout.writeln(
    '  velora install <package> [--no-pub-get] [--no-wire]  '
    '(e.g. velora install velora_offline)',
  );
  stdout.writeln('  velora doctor');
}

void _new(List<String> args) {
  if (args.isEmpty) _fail('Missing app name.');
  final rootName = args.first;
  final appName = p.basename(p.normalize(rootName));
  final packageName = _snake(appName);
  final title = _title(packageName);
  final root = Directory(rootName)..createSync(recursive: true);

  _write(p.join(root.path, 'pubspec.yaml'), _pubspec(packageName, root.path));
  _write(p.join(root.path, 'analysis_options.yaml'), _analysisOptions());
  _write(p.join(root.path, 'lib', 'main.dart'), _main(packageName, title));
  _write(
    p.join(root.path, 'lib', 'app', 'routes', 'app_routes.dart'),
    _appRoutes(),
  );
  _write(
    p.join(root.path, 'lib', 'app', 'routes', 'app_router.dart'),
    _appRouter(),
  );
  _write(
    p.join(root.path, 'lib', 'app', 'modules', 'splash', 'splash_module.dart'),
    _splashModule(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'splash',
      'controllers',
      'splash_controller.dart',
    ),
    _splashController(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'splash',
      'pages',
      'splash_page.dart',
    ),
    _splashPage(title),
  );
  _write(
    p.join(root.path, 'lib', 'app', 'modules', 'auth', 'auth_module.dart'),
    _authModule(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'auth',
      'controllers',
      'login_controller.dart',
    ),
    _loginController(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'auth',
      'pages',
      'login_page.dart',
    ),
    _loginPage(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'dashboard',
      'dashboard_module.dart',
    ),
    _dashboardModule(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'dashboard',
      'controllers',
      'dashboard_controller.dart',
    ),
    _dashboardController(),
  );
  _write(
    p.join(
      root.path,
      'lib',
      'app',
      'modules',
      'dashboard',
      'pages',
      'dashboard_page.dart',
    ),
    _dashboardPage(title),
  );
  _write(
    p.join(root.path, 'lib', 'resources', 'theme', 'app_theme.dart'),
    _appTheme(),
  );
  _writeAi(root.path, title);
  stdout.writeln('Created Velora app: $rootName');
}

void _makeModule(List<String> args) {
  if (args.isEmpty) _fail('Missing module name.');
  final name = _snake(args.first);
  final crud = args.contains('--crud');
  final className = _pascal(name);
  final title = _title(name);
  final base = p.join('lib', 'app', 'modules', name);

  _write(p.join(base, '${name}_module.dart'), _moduleFactory(name, className));
  _write(
    p.join(base, '${name}_routes.dart'),
    _moduleRoutes(name, className, crud),
  );
  _write(p.join(base, 'models', '${name}_model.dart'), _model(className));
  _write(
    p.join(base, 'data', '${name}_remote_data_source.dart'),
    _remoteDataSource(name, className),
  );
  _write(
    p.join(base, 'data', '${name}_repository.dart'),
    _repository(name, className),
  );
  _write(
    p.join(base, 'services', '${name}_service.dart'),
    _service(name, className),
  );
  _write(
    p.join(base, 'controllers', '${name}_controller.dart'),
    _controller(name, className),
  );
  _write(
    p.join(base, 'pages', '${name}_index_page.dart'),
    _indexPage(name, className, title, crud),
  );
  if (crud) {
    _write(
      p.join(base, 'pages', '${name}_show_page.dart'),
      _showPage(name, className, title),
    );
    _write(
      p.join(base, 'pages', '${name}_create_page.dart'),
      _createPage(name, className, title),
    );
    _write(
      p.join(base, 'pages', '${name}_edit_page.dart'),
      _editPage(name, className, title),
    );
  }
  stdout.writeln('Created ${crud ? 'CRUD ' : ''}module: $name');
}

void _makeAuth(List<String> args) {
  if (!args.contains('--sanctum')) _fail('Only --sanctum auth is supported.');
  _write(
    p.join('lib', 'app', 'modules', 'auth', 'auth_module.dart'),
    _authModule(),
  );
  _write(
    p.join(
      'lib',
      'app',
      'modules',
      'auth',
      'controllers',
      'login_controller.dart',
    ),
    _loginController(),
  );
  _write(
    p.join('lib', 'app', 'modules', 'auth', 'pages', 'login_page.dart'),
    _loginPage(),
  );
  stdout.writeln('Created Sanctum auth module.');
}

void _makeNotifications(List<String> args) {
  if (args.isNotEmpty) _fail('make:notifications does not accept arguments.');

  final base = p.join('lib', 'app', 'modules', 'notifications');
  _write(p.join(base, 'notifications_feature.dart'), _notificationsFeature());
  _write(p.join(base, 'notifications_binding.dart'), _notificationsBinding());
  _write(p.join(base, 'notifications_routes.dart'), _notificationsRoutes());
  _write(
    p.join(base, 'presentation', 'notifications_controller.dart'),
    _notificationsController(),
  );
  _write(
    p.join(base, 'presentation', 'views', 'notifications_index_page.dart'),
    _notificationsIndexPage(),
  );
  _write(
    p.join(base, 'presentation', 'views', 'notification_details_page.dart'),
    _notificationDetailsPage(),
  );
  _write(
    p.join(base, 'presentation', 'widgets', 'notification_tile.dart'),
    _notificationTile(),
  );
  _write(
    p.join(base, 'presentation', 'widgets', 'notification_badge.dart'),
    _notificationBadge(),
  );
  _write(
    p.join(base, 'application', 'notification_service.dart'),
    _notificationService(),
  );
  _write(
    p.join(base, 'domain', 'repositories', 'notification_repository.dart'),
    _notificationRepositoryContract(),
  );
  _write(
    p.join(base, 'domain', 'entities', 'app_notification.dart'),
    _appNotificationEntity(),
  );
  _write(
    p.join(base, 'domain', 'entities', 'push_message.dart'),
    _pushMessageEntity(),
  );
  _write(
    p.join(base, 'domain', 'entities', 'device_token.dart'),
    _deviceTokenEntity(),
  );
  _write(
    p.join(base, 'data', 'repositories', 'notification_repository_impl.dart'),
    _notificationRepositoryImpl(),
  );
  _write(
    p.join(base, 'data', 'datasources', 'notification_remote_datasource.dart'),
    _notificationRemoteDataSource(),
  );
  _write(p.join(base, 'data', 'adapters', 'push_adapter.dart'), _pushAdapter());
  _write(
    p.join(base, 'data', 'adapters', 'fcm_push_adapter.dart'),
    _fcmPushAdapter(),
  );
  _write(
    p.join(base, 'data', 'adapters', 'local_notification_adapter.dart'),
    _localNotificationAdapter(),
  );
  _write(
    p.join(base, 'data', 'adapters', 'noop_push_adapter.dart'),
    _noopPushAdapter(),
  );
  _writeNotificationsAi();
  _writePushReminderDocs(includeFcm: true, includeLocal: true);
  stdout.writeln('Created notifications module.');
}

void _installPush(List<String> args) {
  final fcm = args.contains('--fcm');
  final local = args.contains('--local');
  if (args.length != 1 || fcm == local) {
    _fail('Use exactly one push installer: install:push --fcm or --local.');
  }

  _writeNotificationsAi();
  _writePushReminderDocs(includeFcm: fcm, includeLocal: local);
  if (fcm) {
    _write(
      p.join('web', 'firebase-messaging-sw.js'),
      _firebaseMessagingServiceWorker(),
    );
    stdout.writeln('Installed FCM push placeholders.');
    return;
  }

  _write(
    p.join(
      'lib',
      'app',
      'modules',
      'notifications',
      'data',
      'adapters',
      'local_notification_adapter.dart',
    ),
    _localNotificationAdapter(),
  );
  stdout.writeln('Installed local notification placeholder.');
}

void _install(List<String> args) {
  final flags = <String>{'--no-pub-get', '--no-wire'};
  final positional = args.where((arg) => !flags.contains(arg)).toList();
  final noPubGet = args.contains('--no-pub-get');
  final noWire = args.contains('--no-wire');

  if (positional.isEmpty) {
    _fail(
      'Missing package name. Available packages: '
      '${veloraPackageCatalog.keys.join(', ')}',
    );
  }
  final name = positional.first;
  final package = veloraPackageCatalog[name];
  if (package == null) {
    _fail(
      "Unknown package '$name'. Available packages: "
      '${veloraPackageCatalog.keys.join(', ')}',
    );
  }

  final pubspecFile = File(p.join(Directory.current.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    _fail('Run this inside a Velora app (no pubspec.yaml found).');
  }

  final updatedPubspec = addDependencyToPubspec(
    pubspecFile.readAsStringSync(),
    package.name,
    package.constraint,
  );
  pubspecFile.writeAsStringSync(updatedPubspec);
  stdout.writeln('Added ${package.name}: ${package.constraint} to pubspec.yaml.');

  if (!noWire) {
    final mainFile = File(p.join(Directory.current.path, 'lib', 'main.dart'));
    if (!mainFile.existsSync()) {
      stdout.writeln(
        'Could not find lib/main.dart. Wire it manually: add '
        '${package.importLine} and pass plugins: [${package.pluginExpr}] '
        'to Velora.boot(...).',
      );
    } else {
      final result = wirePluginIntoBoot(
        mainFile.readAsStringSync(),
        importLine: package.importLine,
        pluginExpr: package.pluginExpr,
      );
      mainFile.writeAsStringSync(result.content);
      if (result.wired) {
        stdout.writeln('Wired ${package.pluginExpr} into Velora.boot().');
      } else {
        stdout.writeln(
          'Could not find Velora.boot(...) in lib/main.dart. Wire it '
          'manually: add plugins: [${package.pluginExpr}] to Velora.boot(...).',
        );
      }
    }
  }

  if (!noPubGet) {
    var success = false;
    try {
      final flutterResult = Process.runSync(
        'flutter',
        <String>['pub', 'get'],
        workingDirectory: Directory.current.path,
      );
      success = flutterResult.exitCode == 0;
    } catch (_) {
      // flutter not on PATH — fall through to dart.
    }
    if (!success) {
      try {
        final dartResult = Process.runSync(
          'dart',
          <String>['pub', 'get'],
          workingDirectory: Directory.current.path,
        );
        success = dartResult.exitCode == 0;
      } catch (_) {
        // dart not on PATH either.
      }
    }
    if (!success) {
      stdout.writeln(
        'Warning: could not run `flutter pub get` or `dart pub get` '
        'automatically. Run one of them manually to fetch ${package.name}.',
      );
    }
  }

  for (final note in package.notes) {
    stdout.writeln(note);
  }
  stdout.writeln('Installed ${package.name}.');
}

void _doctor() {
  stdout.writeln('Velora doctor');
  stdout.writeln('Dart: ${Platform.version.split('\n').first}');
  stdout.writeln('Project: ${Directory.current.path}');
  stdout.writeln('Status: OK');
}

void _writeAi(String root, String title) {
  final dir = p.join(root, '.ai');
  _write(p.join(dir, 'project-context.md'), '''# Project Context

$title is a Velora Flutter app generated by Velora CLI.

Primary entry points:
- `lib/main.dart` boots Velora services and configures the app shell.
- `lib/app/routes` owns route names and the route factory.
- `lib/app/modules` contains feature-local modules.
''');
  _write(p.join(dir, 'architecture.md'), '''# Architecture

Use this flow for feature work:

Page -> Controller -> Service -> Repository -> RemoteDataSource -> Velora.api

Rules:
- Pages render UI and call controller methods.
- Controllers coordinate state, validation, navigation, and user feedback.
- Services own business operations and call repositories.
- Repositories choose data sources and keep persistence decisions out of services.
- Remote data sources are the only layer that calls `Velora.api`.
- Models expose `fromJson` and `toJson` for analyzer-friendly API boundaries.
''');
  _write(p.join(dir, 'conventions.md'), '''# Conventions

Feature modules live in `lib/app/modules/<module>`.

CRUD module layout:
- `<module>_module.dart` local dependency factory.
- `<module>_routes.dart` route constants/helpers.
- `models/<module>_model.dart` DTO/domain model.
- `data/<module>_remote_data_source.dart` API adapter.
- `data/<module>_repository.dart` repository implementation.
- `services/<module>_service.dart` business service.
- `controllers/<module>_controller.dart` view controller.
- `pages/<module>_index_page.dart`, plus `show/create/edit` pages for CRUD.

Do not import transitive packages directly from app code unless they are declared in `pubspec.yaml`.
''');
  _write(p.join(dir, 'api-contract.md'), '''# API Contract

Default API shape follows Laravel Sanctum JSON endpoints.

Authentication:
- `POST /auth/login` expects `email` and `password`.
- Login response must include `token` or `access_token`, plus `user`.
- `POST /auth/logout` revokes the active token.
- `GET /auth/me` returns the current user.

CRUD modules expect RESTful resources:
- `GET /<resource>` returns a list or `{ "data": [...] }`.
- `GET /<resource>/{id}` returns an object or `{ "data": {...} }`.
- `POST /<resource>` creates a resource.
- `PUT /<resource>/{id}` updates a resource.
- `DELETE /<resource>/{id}` deletes a resource.
''');
  _write(p.join(dir, 'module-map.json'), '''{
  "modules": [
    {"name": "splash", "route": "/"},
    {"name": "auth", "route": "/login"},
    {"name": "dashboard", "route": "/dashboard"}
  ]
}
''');
  _write(p.join(dir, 'agent-rules.md'), '''# Agent Rules

- Keep generated modules analyzer-friendly.
- Follow Page -> Controller -> Service -> Repository -> RemoteDataSource.
- Keep feature dependencies local to each module factory.
- Add routes in `lib/app/routes/app_routes.dart` and `app_router.dart` when exposing a module from app navigation.
- Avoid broad refactors while adding one feature.
''');
  _write(p.join(dir, 'tasks.md'), '''# Tasks

- Set `apiBaseUrl` in `lib/main.dart`.
- Replace sample login credentials in the login page.
- Add feature routes to `AppRoutes` and `AppRouter` as modules are created.
''');
  _write(p.join(dir, 'notifications.md'), '''# Notification Architecture

Velora notifications use:

- NotificationService as the single source of truth.
- NotificationRepository for Laravel API access.
- FcmPushAdapter for remote push when Firebase is configured.
- LocalNotificationAdapter for local display.
- NoopPushAdapter for mock/noop mode during local development.
- Feature-aware routing and permission-aware display.

Rules:

- Do not store notification state in controllers.
- Do not directly use FirebaseMessaging inside views/controllers.
- Do not directly use FlutterLocalNotificationsPlugin inside views/controllers.
- Use Velora.notify when the runtime facade is available, otherwise inject NotificationService from the generated binding.
''');
}

String _pubspec(String name, String root) {
  final veloraPath = _veloraPackagePath(root);
  return '''name: $name
description: Velora generated app.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.1

dependencies:
  flutter:
    sdk: flutter
  velora:
    path: $veloraPath

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';
}

String _analysisOptions() => '''include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
''';

String _main(String packageName, String title) =>
    r'''import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'app/routes/app_router.dart';
import 'app/routes/app_routes.dart';
import 'resources/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Velora.boot(
    config: const VeloraConfig(
      appName: '{{title}}',
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.example.com/api',
      ),
    ),
  );
  runApp(const {{appClass}}());
}

class {{appClass}} extends StatelessWidget {
  const {{appClass}}({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{title}}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
'''
        .replaceAll('{{title}}', title)
        .replaceAll('{{appClass}}', '${_pascal(packageName)}App');

String _appRoutes() => '''class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
}
''';

String _appRouter() => r'''import 'package:flutter/material.dart';

import '../modules/auth/auth_module.dart';
import '../modules/auth/pages/login_page.dart';
import '../modules/dashboard/dashboard_module.dart';
import '../modules/dashboard/pages/dashboard_page.dart';
import '../modules/splash/pages/splash_page.dart';
import '../modules/splash/splash_module.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.splash => _page(
          settings,
          SplashPage(controller: SplashModule.controller()),
        ),
      AppRoutes.login => _page(
          settings,
          LoginPage(controller: AuthModule.loginController()),
        ),
      AppRoutes.dashboard => _page(
          settings,
          DashboardPage(controller: DashboardModule.controller()),
        ),
      _ => _page(settings, UnknownRoutePage(routeName: settings.name)),
    };
  }

  static MaterialPageRoute<void> _page(RouteSettings settings, Widget child) {
    return MaterialPageRoute<void>(settings: settings, builder: (_) => child);
  }
}

class UnknownRoutePage extends StatelessWidget {
  final String? routeName;

  const UnknownRoutePage({required this.routeName, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route not found')),
      body: Center(child: Text('Unknown route: ${routeName ?? 'unknown'}')),
    );
  }
}
''';

String _splashModule() => '''import 'controllers/splash_controller.dart';

class SplashModule {
  const SplashModule._();

  static SplashController controller() => SplashController();
}
''';

String _splashController() => r'''import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../routes/app_routes.dart';

class SplashController extends VeloraController {
  String get nextRoute => Velora.auth.check ? AppRoutes.dashboard : AppRoutes.login;

  void continueToApp(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }
}
''';

String _splashPage(String title) =>
    r'''import 'package:flutter/material.dart';

import '../controllers/splash_controller.dart';

class SplashPage extends StatefulWidget {
  final SplashController controller;

  const SplashPage({required this.controller, super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.continueToApp(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.bolt, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '{{title}}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
'''
        .replaceAll('{{title}}', title);

String _authModule() => '''import 'controllers/login_controller.dart';

class AuthModule {
  const AuthModule._();

  static LoginController loginController() => LoginController();
}
''';

String _loginController() => r'''import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../routes/app_routes.dart';

class LoginController extends VeloraController {
  final emailController = TextEditingController(text: 'admin@example.com');
  final passwordController = TextEditingController(text: 'password');

  Future<void> login(BuildContext context) async {
    final user = await run(
      () => Velora.auth.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      ),
      showLoader: true,
      successMessage: 'Welcome back',
    );

    if (user != null && context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  void closeTextFields() {
    emailController.dispose();
    passwordController.dispose();
  }
}
''';

String _loginPage() => r'''import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  final LoginController controller;

  const LoginPage({required this.controller, super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    widget.controller.closeTextFields();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: widget.controller.emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.controller.passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          widget.controller.login(context);
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''';

String _dashboardModule() => '''import 'controllers/dashboard_controller.dart';

class DashboardModule {
  const DashboardModule._();

  static DashboardController controller() => DashboardController();
}
''';

String _dashboardController() => r'''import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../routes/app_routes.dart';

class DashboardController extends VeloraController {
  AuthUser? get user => Velora.auth.user;
  String get apiBaseUrl => Velora.config.apiBaseUrl;

  Future<void> logout(BuildContext context) async {
    final loggedOut = await run(() async {
      await Velora.auth.logout();
      return true;
    });

    if (loggedOut == true && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }
}
''';

String _dashboardPage(String title) =>
    r'''import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  final DashboardController controller;

  const DashboardPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Logout',
            onPressed: () => controller.logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('{{title}}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.name ?? 'Guest user'),
              subtitle: Text(user?.email ?? 'No email loaded'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('API base URL'),
              subtitle: Text(controller.apiBaseUrl),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.extension),
              title: Text('Next step'),
              subtitle: Text('Run velora make:module posts --crud, then add its route to AppRouter.'),
            ),
          ),
        ],
      ),
    );
  }
}
'''
        .replaceAll('{{title}}', title);

String _appTheme() => '''import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => VeloraTheme.light(seedColor: Colors.indigo);
  static ThemeData dark() => VeloraTheme.dark(seedColor: Colors.indigo);
}
''';

String _moduleFactory(String name, String className) =>
    '''import 'controllers/${name}_controller.dart';
import 'data/${name}_remote_data_source.dart';
import 'data/${name}_repository.dart';
import 'services/${name}_service.dart';

class ${className}Module {
  const ${className}Module._();

  static ${className}Controller controller() {
    final dataSource = ${className}RemoteDataSource();
    final repository = ${className}Repository(dataSource);
    final service = ${className}Service(repository);
    return ${className}Controller(service);
  }
}
''';

String _moduleRoutes(String name, String className, bool crud) {
  final crudRoutes = crud
      ? r'''
  static String show(int id) => '$index/$id';
  static const create = '$index/create';
  static String edit(int id) => '$index/$id/edit';
'''
      : '';
  return '''class ${className}Routes {
  static const index = '/$name';
$crudRoutes}
''';
}

String _model(String className) =>
    r'''class {{className}}Model {
  final int? id;
  final String name;
  final Map<String, dynamic> attributes;

  const {{className}}Model({
    this.id,
    required this.name,
    this.attributes = const <String, dynamic>{},
  });

  factory {{className}}Model.fromJson(Map<String, dynamic> json) {
    return {{className}}Model(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      attributes: Map<String, dynamic>.unmodifiable(json),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...attributes,
      'id': id,
      'name': name,
    };
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
'''
        .replaceAll('{{className}}', className);

String _remoteDataSource(String name, String className) =>
    r'''import 'package:velora/velora.dart';

import '../models/{{name}}_model.dart';

class {{className}}RemoteDataSource implements VeloraRemoteDataSource<{{className}}Model, int> {
  final String endpoint;

  const {{className}}RemoteDataSource({this.endpoint = '/{{name}}'});

  @override
  Future<List<{{className}}Model>> index() async {
    final response = await Velora.api.get<List<{{className}}Model>>(
      endpoint,
      parser: (value) {
        final data = _unwrapData(value);
        final items = data is List ? data : const <Object?>[];
        return items.map(_modelFromJson).toList(growable: false);
      },
    );
    return response.data ?? <{{className}}Model>[];
  }

  @override
  Future<{{className}}Model> show(int id) async {
    final response = await Velora.api.get<{{className}}Model>(
      '$endpoint/$id',
      parser: _modelFromJson,
    );
    return response.data ?? {{className}}Model.fromJson(const <String, dynamic>{});
  }

  @override
  Future<{{className}}Model> store(Map<String, dynamic> data) async {
    final response = await Velora.api.post<{{className}}Model>(
      endpoint,
      data: data,
      parser: _modelFromJson,
    );
    return response.data ?? {{className}}Model.fromJson(data);
  }

  @override
  Future<{{className}}Model> update(int id, Map<String, dynamic> data) async {
    final response = await Velora.api.put<{{className}}Model>(
      '$endpoint/$id',
      data: data,
      parser: _modelFromJson,
    );
    return response.data ?? {{className}}Model.fromJson(<String, dynamic>{...data, 'id': id});
  }

  @override
  Future<void> destroy(int id) async {
    await Velora.api.delete<Object?>('$endpoint/$id');
  }

  Object? _unwrapData(Object? value) {
    if (value is Map && value.containsKey('data')) return value['data'];
    return value;
  }

  {{className}}Model _modelFromJson(Object? value) {
    final data = _unwrapData(value);
    if (data is Map) {
      return {{className}}Model.fromJson(Map<String, dynamic>.from(data));
    }
    return {{className}}Model.fromJson(const <String, dynamic>{});
  }
}
'''
        .replaceAll('{{name}}', name)
        .replaceAll('{{className}}', className);

String _repository(String name, String className) =>
    '''import 'package:velora/velora.dart';

import '../models/${name}_model.dart';
import '${name}_remote_data_source.dart';

class ${className}Repository implements VeloraRepository<${className}Model, int> {
  final ${className}RemoteDataSource remoteDataSource;

  const ${className}Repository(this.remoteDataSource);

  @override
  Future<List<${className}Model>> index() => remoteDataSource.index();

  @override
  Future<${className}Model> show(int id) => remoteDataSource.show(id);

  @override
  Future<${className}Model> store(Map<String, dynamic> data) => remoteDataSource.store(data);

  @override
  Future<${className}Model> update(int id, Map<String, dynamic> data) => remoteDataSource.update(id, data);

  @override
  Future<void> destroy(int id) => remoteDataSource.destroy(id);
}
''';

String _service(String name, String className) =>
    '''import '../data/${name}_repository.dart';
import '../models/${name}_model.dart';

class ${className}Service {
  final ${className}Repository repository;

  const ${className}Service(this.repository);

  Future<List<${className}Model>> index() => repository.index();
  Future<${className}Model> show(int id) => repository.show(id);
  Future<${className}Model> store(Map<String, dynamic> data) => repository.store(data);
  Future<${className}Model> update(int id, Map<String, dynamic> data) => repository.update(id, data);
  Future<void> destroy(int id) => repository.destroy(id);
}
''';

String _controller(String name, String className) =>
    r'''import 'package:velora/velora.dart';

import '../models/{{name}}_model.dart';
import '../services/{{name}}_service.dart';

class {{className}}Controller extends VeloraController {
  final {{className}}Service service;

  {{className}}Controller(this.service);

  Future<List<{{className}}Model>> load() async {
    final result = await run<List<{{className}}Model>>(service.index);
    return result ?? <{{className}}Model>[];
  }

  Future<{{className}}Model?> show(int id) {
    return run<{{className}}Model>(() => service.show(id));
  }

  Future<{{className}}Model?> create(Map<String, dynamic> data) {
    return run<{{className}}Model>(
      () => service.store(data),
      successMessage: '{{className}} created',
    );
  }

  Future<{{className}}Model?> update(int id, Map<String, dynamic> data) {
    return run<{{className}}Model>(
      () => service.update(id, data),
      successMessage: '{{className}} updated',
    );
  }

  Future<bool> destroy(int id) async {
    final deleted = await run<bool>(
      () async {
        await service.destroy(id);
        return true;
      },
      successMessage: '{{className}} deleted',
    );
    return deleted ?? false;
  }
}
'''
        .replaceAll('{{name}}', name)
        .replaceAll('{{className}}', className);

String _indexPage(String name, String className, String title, bool crud) {
  if (!crud) {
    return r'''import 'package:flutter/material.dart';

import '../controllers/{{name}}_controller.dart';
import '../models/{{name}}_model.dart';

class {{className}}IndexPage extends StatefulWidget {
  final {{className}}Controller controller;

  const {{className}}IndexPage({required this.controller, super.key});

  @override
  State<{{className}}IndexPage> createState() => _{{className}}IndexPageState();
}

class _{{className}}IndexPageState extends State<{{className}}IndexPage> {
  late Future<List<{{className}}Model>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{title}}')),
      body: FutureBuilder<List<{{className}}Model>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? <{{className}}Model>[];
          if (items.isEmpty) return const Center(child: Text('No records found.'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(title: Text(item.name.isEmpty ? 'Untitled' : item.name));
            },
          );
        },
      ),
    );
  }
}
'''
        .replaceAll('{{name}}', name)
        .replaceAll('{{className}}', className)
        .replaceAll('{{title}}', title);
  }

  return r'''import 'package:flutter/material.dart';

import '../controllers/{{name}}_controller.dart';
import '../models/{{name}}_model.dart';
import '{{name}}_create_page.dart';
import '{{name}}_edit_page.dart';
import '{{name}}_show_page.dart';

class {{className}}IndexPage extends StatefulWidget {
  final {{className}}Controller controller;

  const {{className}}IndexPage({required this.controller, super.key});

  @override
  State<{{className}}IndexPage> createState() => _{{className}}IndexPageState();
}

class _{{className}}IndexPageState extends State<{{className}}IndexPage> {
  late Future<List<{{className}}Model>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.controller.load();
  }

  void _refresh() {
    setState(() {
      _items = widget.controller.load();
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => {{className}}CreatePage(controller: widget.controller),
      ),
    );
    if (created == true && mounted) _refresh();
  }

  Future<void> _openEdit({{className}}Model item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => {{className}}EditPage(controller: widget.controller, item: item),
      ),
    );
    if (updated == true && mounted) _refresh();
  }

  Future<void> _openShow({{className}}Model item) async {
    final id = item.id;
    if (id == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => {{className}}ShowPage(controller: widget.controller, id: id),
      ),
    );
  }

  Future<void> _delete({{className}}Model item) async {
    final id = item.id;
    if (id == null) return;
    final deleted = await widget.controller.destroy(id);
    if (deleted && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{title}}'),
        actions: <Widget>[
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: FutureBuilder<List<{{className}}Model>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final items = snapshot.data ?? <{{className}}Model>[];
          if (items.isEmpty) return const Center(child: Text('No records found.'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.name.isEmpty ? 'Untitled' : item.name),
                subtitle: item.id == null ? null : Text('ID: ${item.id}'),
                onTap: () => _openShow(item),
                trailing: Wrap(
                  spacing: 4,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _openEdit(item),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _delete(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
'''
      .replaceAll('{{name}}', name)
      .replaceAll('{{className}}', className)
      .replaceAll('{{title}}', title);
}

String _showPage(String name, String className, String title) =>
    r'''import 'dart:convert';

import 'package:flutter/material.dart';

import '../controllers/{{name}}_controller.dart';
import '../models/{{name}}_model.dart';

class {{className}}ShowPage extends StatefulWidget {
  final {{className}}Controller controller;
  final int id;

  const {{className}}ShowPage({required this.controller, required this.id, super.key});

  @override
  State<{{className}}ShowPage> createState() => _{{className}}ShowPageState();
}

class _{{className}}ShowPageState extends State<{{className}}ShowPage> {
  late Future<{{className}}Model?> _item;

  @override
  void initState() {
    super.initState();
    _item = widget.controller.show(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{title}} details')),
      body: FutureBuilder<{{className}}Model?>(
        future: _item,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) return const Center(child: Text('Record not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(item.name.isEmpty ? 'Untitled' : item.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SelectableText(const JsonEncoder.withIndent('  ').convert(item.toJson())),
            ],
          );
        },
      ),
    );
  }
}
'''
        .replaceAll('{{name}}', name)
        .replaceAll('{{className}}', className)
        .replaceAll('{{title}}', title);

String _createPage(String name, String className, String title) =>
    r'''import 'package:flutter/material.dart';

import '../controllers/{{name}}_controller.dart';

class {{className}}CreatePage extends StatefulWidget {
  final {{className}}Controller controller;

  const {{className}}CreatePage({required this.controller, super.key});

  @override
  State<{{className}}CreatePage> createState() => _{{className}}CreatePageState();
}

class _{{className}}CreatePageState extends State<{{className}}CreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final created = await widget.controller.create(<String, dynamic>{
      'name': _nameController.text.trim(),
    });
    if (created != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create {{title}}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
'''
        .replaceAll('{{name}}', name)
        .replaceAll('{{className}}', className)
        .replaceAll('{{title}}', title);

String _editPage(String name, String className, String title) =>
    r'''import 'package:flutter/material.dart';

import '../controllers/{{name}}_controller.dart';
import '../models/{{name}}_model.dart';

class {{className}}EditPage extends StatefulWidget {
  final {{className}}Controller controller;
  final {{className}}Model item;

  const {{className}}EditPage({required this.controller, required this.item, super.key});

  @override
  State<{{className}}EditPage> createState() => _{{className}}EditPageState();
}

class _{{className}}EditPageState extends State<{{className}}EditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = widget.item.id;
    if (id == null) return;
    final updated = await widget.controller.update(id, <String, dynamic>{
      ...widget.item.toJson(),
      'name': _nameController.text.trim(),
    });
    if (updated != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit {{title}}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
'''
        .replaceAll('{{name}}', name)
        .replaceAll('{{className}}', className)
        .replaceAll('{{title}}', title);

String _notificationsFeature() => r'''import 'notifications_binding.dart';
import 'notifications_routes.dart';
import 'presentation/views/notifications_index_page.dart';

class NotificationsFeature {
  const NotificationsFeature._();

  static const route = NotificationsRoutes.index;
  static const binding = NotificationsBinding();

  static NotificationsIndexPage page() {
    return NotificationsIndexPage(controller: binding.controller());
  }
}
''';

String _notificationsBinding() =>
    r'''import 'application/notification_service.dart';
import 'data/adapters/local_notification_adapter.dart';
import 'data/adapters/noop_push_adapter.dart';
import 'data/datasources/notification_remote_datasource.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'presentation/notifications_controller.dart';

class NotificationsBinding {
  const NotificationsBinding();

  NotificationService service() {
    final remoteDataSource = NotificationRemoteDataSource();
    final repository = NotificationRepositoryImpl(remoteDataSource);
    return NotificationService(
      repository: repository,
      pushAdapter: const NoopPushAdapter(),
      localAdapter: const LocalNotificationAdapter(),
    );
  }

  NotificationsController controller() {
    return NotificationsController(service());
  }
}
''';

String _notificationsRoutes() => r'''class NotificationsRoutes {
  static const index = '/notifications';

  static String details(String id) => '$index/$id';
}
''';

String _notificationsController() =>
    r'''import '../application/notification_service.dart';
import '../domain/entities/app_notification.dart';

class NotificationsController {
  final NotificationService service;

  const NotificationsController(this.service);

  Future<void> init() => service.initForUser();
  Future<void> refresh() => service.fetch();
  Future<void> markAsRead(String id) => service.markAsRead(id);
  Future<void> markAllAsRead() => service.markAllAsRead();
  Future<void> handleTap(AppNotification notification) => service.handleTap(notification);
}
''';

String _notificationsIndexPage() => r'''import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';
import '../notifications_controller.dart';
import '../widgets/notification_badge.dart';
import '../widgets/notification_tile.dart';
import 'notification_details_page.dart';

class NotificationsIndexPage extends StatefulWidget {
  final NotificationsController controller;

  const NotificationsIndexPage({required this.controller, super.key});

  @override
  State<NotificationsIndexPage> createState() => _NotificationsIndexPageState();
}

class _NotificationsIndexPageState extends State<NotificationsIndexPage> {
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.init();
    } catch (error) {
      _error = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification notification) async {
    await widget.controller.handleTap(notification);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailsPage(notification: notification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          NotificationBadge(countListenable: widget.controller.service.unreadCount),
          IconButton(
            tooltip: 'Mark all read',
            onPressed: () => widget.controller.markAllAsRead(),
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) return Center(child: Text(error.toString()));

    return ValueListenableBuilder<List<AppNotification>>(
      valueListenable: widget.controller.service.notifications,
      builder: (context, notifications, _) {
        if (notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => widget.controller.refresh(),
            child: ListView(
              children: const <Widget>[
                SizedBox(height: 160),
                Center(child: Text('No notifications yet.')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => widget.controller.refresh(),
          child: ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () => _open(notification),
                onMarkRead: () => widget.controller.markAsRead(notification.id),
              );
            },
          ),
        );
      },
    );
  }
}
''';

String _notificationDetailsPage() => r'''import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';

class NotificationDetailsPage extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailsPage({required this.notification, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(notification.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(notification.body),
          const SizedBox(height: 16),
          if (notification.route != null) Text('Route: ${notification.route}'),
          if (notification.feature != null) Text('Feature: ${notification.feature}'),
          if (notification.permission != null) Text('Permission: ${notification.permission}'),
        ],
      ),
    );
  }
}
''';

String _notificationTile() => r'''import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;

  const NotificationTile({
    required this.notification,
    this.onTap,
    this.onMarkRead,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(notification.isRead ? Icons.notifications_none : Icons.notifications_active),
      title: Text(notification.title),
      subtitle: Text(notification.body),
      onTap: onTap,
      trailing: notification.isRead
          ? null
          : TextButton(onPressed: onMarkRead, child: const Text('Read')),
    );
  }
}
''';

String _notificationBadge() => r'''import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final ValueListenable<int> countListenable;

  const NotificationBadge({required this.countListenable, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: countListenable,
      builder: (context, count, _) {
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(child: Text(count > 99 ? '99+' : '$count')),
        );
      },
    );
  }
}
''';

String _notificationService() => r'''import 'package:flutter/foundation.dart';

import '../data/adapters/local_notification_adapter.dart';
import '../data/adapters/push_adapter.dart';
import '../domain/entities/app_notification.dart';
import '../domain/repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository repository;
  final PushAdapter pushAdapter;
  final LocalNotificationAdapter localAdapter;

  final ValueNotifier<List<AppNotification>> notifications = ValueNotifier(<AppNotification>[]);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> permissionGranted = ValueNotifier<bool>(false);
  final ValueNotifier<String?> pushToken = ValueNotifier<String?>(null);
  final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);

  NotificationService({
    required this.repository,
    required this.pushAdapter,
    required this.localAdapter,
  });

  Future<void> initForUser() async {
    permissionGranted.value = await pushAdapter.requestPermission();
    pushToken.value = await pushAdapter.registerDeviceToken();
    await fetch();
    initialized.value = true;
  }

  Future<void> disposeForUser() async {
    await pushAdapter.dispose();
    notifications.value = <AppNotification>[];
    unreadCount.value = 0;
    pushToken.value = null;
    initialized.value = false;
  }

  Future<void> fetch() async {
    final items = await repository.fetch();
    notifications.value = items;
    unreadCount.value = items.where((item) => !item.isRead).length;
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);
    notifications.value = notifications.value
        .map((item) => item.id == id ? item.copyWith(readAt: DateTime.now()) : item)
        .toList(growable: false);
    unreadCount.value = notifications.value.where((item) => !item.isRead).length;
  }

  Future<void> markAllAsRead() async {
    await repository.markAllAsRead();
    final now = DateTime.now();
    notifications.value = notifications.value
        .map((item) => item.isRead ? item : item.copyWith(readAt: now))
        .toList(growable: false);
    unreadCount.value = 0;
  }

  Future<void> showLocal({required String title, required String body, Map<String, Object?> data = const <String, Object?>{}}) {
    return localAdapter.show(title: title, body: body, data: data);
  }

  Future<void> scheduleLocal({required String id, required String title, required String body, required DateTime dateTime}) {
    return localAdapter.schedule(id: id, title: title, body: body, dateTime: dateTime);
  }

  Future<void> cancelLocal(String id) => localAdapter.cancel(id);
  Future<void> cancelAllLocal() => localAdapter.cancelAll();

  Future<void> handleTap(AppNotification notification) async {
    if (!notification.isRead) await markAsRead(notification.id);
  }
}
''';

String _notificationRepositoryContract() =>
    r'''import '../entities/app_notification.dart';
import '../entities/device_token.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetch();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> registerDevice(DeviceToken token);
  Future<void> unregisterDevice(String token);
}
''';

String _appNotificationEntity() => r'''class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? feature;
  final String? permission;
  final String? route;
  final Map<String, Object?> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.feature,
    this.permission,
    this.route,
    this.data = const <String, Object?>{},
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, Object?> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'in_app',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      feature: json['feature']?.toString(),
      permission: json['permission']?.toString(),
      route: json['route']?.toString(),
      data: _map(json['data']),
      readAt: _date(json['read_at']),
      createdAt: _date(json['created_at']),
    );
  }

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      feature: feature,
      permission: permission,
      route: route,
      data: data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'feature': feature,
        'permission': permission,
        'route': route,
        'data': data,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  static Map<String, Object?> _map(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    return const <String, Object?>{};
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
''';

String _pushMessageEntity() => r'''class PushMessage {
  final String title;
  final String body;
  final Map<String, Object?> data;

  const PushMessage({
    required this.title,
    required this.body,
    this.data = const <String, Object?>{},
  });
}
''';

String _deviceTokenEntity() => r'''class DeviceToken {
  final String token;
  final String platform;
  final String provider;

  const DeviceToken({
    required this.token,
    required this.platform,
    this.provider = 'fcm',
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'token': token,
        'platform': platform,
        'provider': provider,
      };
}
''';

String _notificationRepositoryImpl() =>
    r'''import '../../domain/entities/app_notification.dart';
import '../../domain/entities/device_token.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  const NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AppNotification>> fetch() => remoteDataSource.fetch();

  @override
  Future<void> markAsRead(String id) => remoteDataSource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => remoteDataSource.markAllAsRead();

  @override
  Future<void> registerDevice(DeviceToken token) => remoteDataSource.registerDevice(token);

  @override
  Future<void> unregisterDevice(String token) => remoteDataSource.unregisterDevice(token);
}
''';

String _notificationRemoteDataSource() =>
    r'''import 'package:velora/velora.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/device_token.dart';

class NotificationRemoteDataSource {
  final String notificationsEndpoint;
  final String deviceEndpoint;

  const NotificationRemoteDataSource({
    this.notificationsEndpoint = '/notifications',
    this.deviceEndpoint = '/devices',
  });

  Future<List<AppNotification>> fetch() async {
    final response = await Velora.api.get<List<AppNotification>>(
      notificationsEndpoint,
      parser: (value) {
        final data = _unwrapData(value);
        final items = data is List ? data : const <Object?>[];
        return items.map(_notificationFromJson).toList(growable: false);
      },
    );
    return response.data ?? <AppNotification>[];
  }

  Future<void> markAsRead(String id) async {
    await Velora.api.patch<Object?>('$notificationsEndpoint/$id/read');
  }

  Future<void> markAllAsRead() async {
    await Velora.api.patch<Object?>('$notificationsEndpoint/read-all');
  }

  Future<void> registerDevice(DeviceToken token) async {
    await Velora.api.post<Object?>(deviceEndpoint, data: token.toJson());
  }

  Future<void> unregisterDevice(String token) async {
    await Velora.api.delete<Object?>(deviceEndpoint, data: <String, Object?>{'token': token});
  }

  Object? _unwrapData(Object? value) {
    if (value is Map && value.containsKey('data')) return value['data'];
    return value;
  }

  AppNotification _notificationFromJson(Object? value) {
    final data = _unwrapData(value);
    if (data is Map) return AppNotification.fromJson(Map<String, Object?>.from(data));
    return const AppNotification(id: '', type: 'in_app', title: '', body: '');
  }
}
''';

String _pushAdapter() => r'''abstract class PushAdapter {
  Future<bool> requestPermission();
  Future<String?> registerDeviceToken();
  Future<void> dispose();
}
''';

String _fcmPushAdapter() => r'''import 'push_adapter.dart';

class FcmPushAdapter implements PushAdapter {
  const FcmPushAdapter();

  @override
  Future<bool> requestPermission() async {
    // Placeholder: add firebase_messaging in the app, then request permission here.
    return false;
  }

  @override
  Future<String?> registerDeviceToken() async {
    // Placeholder: return FirebaseMessaging.instance.getToken() when FCM is configured.
    return null;
  }

  @override
  Future<void> dispose() async {}
}
''';

String _localNotificationAdapter() => r'''class LocalNotificationAdapter {
  const LocalNotificationAdapter();

  Future<void> show({required String title, required String body, Map<String, Object?> data = const <String, Object?>{}}) async {
    // Placeholder: wire flutter_local_notifications here when local tray display is enabled.
  }

  Future<void> schedule({required String id, required String title, required String body, required DateTime dateTime}) async {
    // Placeholder: schedule with flutter_local_notifications if your app needs reminders.
  }

  Future<void> cancel(String id) async {}
  Future<void> cancelAll() async {}
}
''';

String _noopPushAdapter() => r'''import 'push_adapter.dart';

class NoopPushAdapter implements PushAdapter {
  const NoopPushAdapter();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> registerDeviceToken() async => null;

  @override
  Future<void> dispose() async {}
}
''';

String _firebaseMessagingServiceWorker() =>
    r'''importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || 'Notification', {
    body: notification.body || '',
    data: payload.data || {},
  });
});
''';

void _writeNotificationsAi() {
  _write(p.join('.ai', 'notifications.md'), '''# Notification Architecture

Velora notifications use:

- NotificationService as the single source of truth.
- NotificationRepository for Laravel API access.
- FcmPushAdapter for remote push when Firebase is configured.
- LocalNotificationAdapter for local display.
- NoopPushAdapter for mock/noop mode during local development.
- Feature-aware routing and permission-aware display.

Rules:

- Do not store notification state in controllers.
- Do not directly use FirebaseMessaging inside views/controllers.
- Do not directly use FlutterLocalNotificationsPlugin inside views/controllers.
- Use Velora.notify when the runtime facade is available, otherwise inject NotificationService from the generated binding.
''');
}

void _writePushReminderDocs({
  required bool includeFcm,
  required bool includeLocal,
}) {
  _write(
    p.join('docs', 'reminders', 'android.md'),
    _androidReminder(includeFcm: includeFcm),
  );
  _write(
    p.join('docs', 'reminders', 'ios.md'),
    _iosReminder(includeFcm: includeFcm),
  );
  _write(
    p.join('docs', 'reminders', 'web.md'),
    _webReminder(includeFcm: includeFcm),
  );
  _write(
    p.join('docs', 'reminders', 'laravel.md'),
    _laravelReminder(includeFcm: includeFcm, includeLocal: includeLocal),
  );
}

String _androidReminder({required bool includeFcm}) =>
    '''# Android Notification Setup Reminder

- Add `android/app/google-services.json` when using FCM.
- Confirm Android Gradle plugin and Google Services plugin setup if FCM is enabled: $includeFcm.
- Add Android 13 notification permission: `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.
- Create a default notification channel before showing local/foreground notifications.
- Keep `NoopPushAdapter` bound for mock/noop mode until Firebase credentials are ready.
''';

String _iosReminder({required bool includeFcm}) =>
    '''# iOS Notification Setup Reminder

- Add `ios/Runner/GoogleService-Info.plist` when using FCM.
- Enable Push Notifications capability if FCM is enabled: $includeFcm.
- Enable Background Modes -> Remote notifications for remote push.
- Upload APNs key to Firebase Console for FCM delivery.
- Request notification permission after login or at a clear user action.
- Keep `NoopPushAdapter` bound for mock/noop mode until APNs/FCM setup is ready.
''';

String _webReminder({required bool includeFcm}) =>
    '''# Web Notification Setup Reminder

- `web/firebase-messaging-sw.js` is generated for FCM installs: $includeFcm.
- Replace placeholder Firebase config values before production use.
- Add Firebase config to `web/index.html` if your app initializes Firebase on web.
- Configure a Web Push certificate / VAPID key in Firebase Console.
- Use mock/noop mode for local development when no browser push credentials exist.
''';

String _laravelReminder({
  required bool includeFcm,
  required bool includeLocal,
}) =>
    '''# Laravel Notification Setup Reminder

- Laravel remains notification source of truth.
- Provide endpoints for `/notifications`, `/notifications/{id}/read`, `/notifications/read-all`, and `/devices`.
- Store `type`, `feature`, `permission`, `title`, `body`, `route`, `data`, `read_at`, and timestamps.
- Register device tokens only when FCM is enabled: $includeFcm.
- Local-only install writes app placeholders and does not require FCM server credentials: $includeLocal.
- Mock/noop mode should return stable notification JSON without sending real push.
''';

String _pascal(String value) {
  return value
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

String _snake(String value) {
  final normalized = value
      .trim()
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '')
      .toLowerCase();
  if (normalized.isEmpty) {
    _fail('Name must contain at least one letter or number.');
  }
  if (RegExp(r'^[0-9]').hasMatch(normalized)) return 'app_$normalized';
  return normalized;
}

String _title(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _veloraPackagePath(String generatedRoot) {
  final cliDir = File(Platform.script.toFilePath()).parent;
  final candidates = <Directory>[
    Directory(p.normalize(p.join(cliDir.path, '..', '..', 'velora'))),
    Directory(
      p.normalize(p.join(cliDir.path, '..', '..', 'Packages', 'velora')),
    ),
    Directory(
      p.normalize(p.join(Directory.current.path, 'Packages', 'velora')),
    ),
    Directory(
      p.normalize(p.join(Directory.current.path, 'packages', 'velora')),
    ),
  ];
  for (final candidate in candidates) {
    if (File(p.join(candidate.path, 'pubspec.yaml')).existsSync()) {
      return p
          .relative(candidate.path, from: generatedRoot)
          .replaceAll('\\', '/');
    }
  }
  return '../velora';
}

void _write(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

Never _fail(String message) {
  stderr.writeln(message);
  exitCode = 64;
  throw const _CliExit();
}

class _CliExit implements Exception {
  const _CliExit();
}
