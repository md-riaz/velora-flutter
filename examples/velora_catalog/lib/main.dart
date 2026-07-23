import 'package:flutter/material.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

import 'app/data/catalog_schema.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final toggleSource = ToggleConnectivitySource();

  await Velora.boot(
    config: const VeloraConfig(
      appName: 'Velora Catalog',
      // No real backend -- MockArticlesRemoteDataSource (constructed by
      // each module, see articles_repository.dart) stands in for one, so
      // this URL is never actually dialed.
      apiBaseUrl: 'https://example.invalid',
      notifications: VeloraNotificationConfig(
        enabled: false,
        provider: PushProvider.none,
      ),
    ),
    plugins: [
      VeloraDbPlugin(
        databaseName: 'velora_catalog.db',
        version: 1,
        migrations: [CreateCatalogSchema()],
      ),
      VeloraOfflinePlugin(source: toggleSource),
    ],
  );

  // Registered so the catalog page can reach this exact instance to flip
  // simulated connectivity from its online/offline `Switch`, and so
  // `articlesRepository()` can hand it to `MockArticlesRemoteDataSource`.
  Get.put<ToggleConnectivitySource>(toggleSource, permanent: true);

  runApp(const VeloraCatalogApp());
}

class VeloraCatalogApp extends StatelessWidget {
  const VeloraCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VeloraApp(
      title: 'Velora Catalog',
      initialRoute: AppRoutes.catalog,
      routes: AppPages.routes,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
    );
  }
}
