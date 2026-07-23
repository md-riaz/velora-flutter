import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../data/article.dart';
import 'catalog_controller.dart';

/// The catalog list -- the app's home screen. A `Switch` in the AppBar flips
/// [ToggleConnectivitySource]'s simulated connectivity so you can watch
/// `VeloraCachedRepository` fall back to the local cache on demand; pull to
/// refresh re-tries the network the same way [CatalogController.load] does
/// on `onInit`.
class CatalogPage extends GetView<CatalogController> {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velora Catalog'),
        actions: [
          Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.isOnline.value ? Icons.wifi : Icons.wifi_off,
                  size: 20,
                ),
                Switch(
                  value: controller.isOnline.value,
                  onChanged: controller.setOnline,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            if (controller.isOnline.value) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You're offline — showing cached articles.",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.articles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = controller.articles;
              if (items.isEmpty) {
                final offline = !controller.isOnline.value;
                return RefreshIndicator(
                  onRefresh: controller.reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: Center(
                          child: Text(
                            offline
                                ? 'No cached articles yet — go online to '
                                      'load.'
                                : 'No articles found.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ArticleTile(
                    article: items[index],
                    onTap: () => controller.openArticle(items[index]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const _ArticleTile({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        article.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${article.author} · ${article.summary}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
