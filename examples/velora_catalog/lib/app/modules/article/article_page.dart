import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'article_controller.dart';

/// A single article's reading view -- title, author, last-updated date, and
/// the summary body. Reads come from a one-shot `show(id)` fetch (see
/// [ArticleController]'s dartdoc); pull to refresh re-tries the network.
class ArticlePage extends GetView<ArticleController> {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Velora.nav.back(),
        ),
        title: const Text('Article'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.reload,
        child: Obx(() {
          final article = controller.article.value;
          if (article == null) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: Center(
                    child: Text(
                      controller.error.value.isEmpty
                          ? 'Article not available.'
                          : controller.error.value,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }

          final updated = article.updatedAtDate;
          final updatedLabel =
              '${updated.year}-${updated.month.toString().padLeft(2, '0')}-'
              '${updated.day.toString().padLeft(2, '0')}';

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${article.author} · updated $updatedLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                article.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        }),
      ),
    );
  }
}
