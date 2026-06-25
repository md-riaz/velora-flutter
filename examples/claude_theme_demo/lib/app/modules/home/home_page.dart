import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../resources/theme/claude_colors.dart';
import '../../routes/app_routes.dart';
import 'conversation_model.dart';
import 'home_controller.dart';

const _kDividerIndent = 72.0;

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      drawer: _AppDrawer(controller: controller),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            centerTitle: false,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Row(
              children: [
                _ClaudeLogo(size: 28),
                const SizedBox(width: 10),
                Text(
                  'Claude',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              Obx(() {
                final isDark = Velora.theme.current == ThemeMode.dark;
                return IconButton(
                  tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      key: ValueKey(isDark),
                    ),
                  ),
                  onPressed: Velora.theme.toggle,
                );
              }),
              const SizedBox(width: 4),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                hintText: 'Search conversations',
                leading: const Icon(Icons.search, size: 20),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: controller.search,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  scheme.surfaceContainerHighest,
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Recent',
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // Error banner
          Obx(() {
            final err = controller.error.value;
            if (err.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: VeloraErrorView(
                message: err,
                onRetry: () => controller.reload(),
              ),
            );
          }),

          // Conversations list
          Obx(() {
            if (controller.isRefreshing.value && controller.items.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              );
            }
            final items = controller.filtered;
            if (items.isEmpty) {
              if (controller.items.isNotEmpty) {
                return const SliverFillRemaining(
                  child: VeloraEmptyState(
                    icon: Icons.search_off,
                    title: 'No results',
                    description: 'Try a different search term.',
                  ),
                );
              }
              return SliverFillRemaining(
                child: VeloraEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations',
                  description: 'Start a new chat to get going.',
                  action: FilledButton.icon(
                    onPressed: controller.startNewChat,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('New chat'),
                  ),
                ),
              );
            }
            return SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                if (controller.searchQuery.value.isEmpty &&
                    index >= items.length - 3) {
                  controller.loadMore();
                }
                final conv = items[index];
                final tile = _ConversationTile(
                  conversation: conv,
                  onTap: () => Velora.nav.to(AppRoutes.chat, arguments: conv),
                );
                if (index == items.length - 1) return tile;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tile,
                    Divider(
                      height: 1,
                      indent: _kDividerIndent,
                      color: scheme.outlineVariant,
                    ),
                  ],
                );
              },
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.startNewChat,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New chat'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation drawer
// ---------------------------------------------------------------------------

class _AppDrawer extends StatelessWidget {
  final HomeController controller;
  const _AppDrawer({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _DrawerHeader(scheme: scheme, textTheme: textTheme),
            const Divider(height: 1),

            // New chat
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('New chat'),
              onTap: () {
                Navigator.pop(context);
                controller.startNewChat();
              },
            ),

            // Starred section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Starred',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Obx(() {
              final starred = controller.starred;
              if (starred.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'No starred conversations',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: starred.map((conv) {
                  return ListTile(
                    leading: Icon(
                      Icons.star_outlined,
                      size: 18,
                      color: ClaudeColors.primary,
                    ),
                    title: Text(
                      conv.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Velora.nav.to(AppRoutes.chat, arguments: conv);
                    },
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  );
                }).toList(),
              );
            }),

            const Spacer(),
            const Divider(height: 1),

            // Settings
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Velora.nav.to(AppRoutes.settings);
              },
            ),

            // Account
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account'),
              onTap: () {
                Navigator.pop(context);
                Velora.nav.to(AppRoutes.account);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _DrawerHeader({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ClaudeColors.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Claude',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClaudeColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Free plan',
                  style: textTheme.labelSmall?.copyWith(
                    color: ClaudeColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                conversation.isStarred
                    ? Icons.star_outlined
                    : Icons.chat_bubble_outline,
                size: 20,
                color: conversation.isStarred
                    ? ClaudeColors.primary
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              conversation.timeAgo,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claude logo widget
// ---------------------------------------------------------------------------

class _ClaudeLogo extends StatelessWidget {
  final double size;
  const _ClaudeLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClaudeColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          'C',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
