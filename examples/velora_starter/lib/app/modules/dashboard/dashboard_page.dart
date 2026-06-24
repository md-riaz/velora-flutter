import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velora/velora.dart';

import '../../routes/app_routes.dart';
import '../auth/logout_state.dart';
import '../auth/starter_auth_service.dart';
import '../notifications/presentation/widgets/notification_badge.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(label: 'Users', value: '2'),
      _MetricCard(
        label: 'Roles',
        value: '${Velora.auth.user?.roles.length ?? 0}',
      ),
      _MetricCard(
        label: 'Permissions',
        value: '${Velora.auth.user?.permissions.length ?? 0}',
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Can(
            permission: 'notifications.view',
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => Velora.nav.to(AppRoutes.notifications),
              icon: const Stack(
                clipBehavior: Clip.none,
                children: [Icon(Icons.notifications), NotificationBadge()],
              ),
            ),
          ),
          Obx(() {
            final loggingOut = isVeloraLogoutRunning();
            return TextButton(
              onPressed: loggingOut
                  ? null
                  : () async {
                      await Get.find<StarterAuthService>().logout();
                      Velora.nav.offAll(AppRoutes.login);
                    },
              child: Text(loggingOut ? 'Logging out…' : 'Logout'),
            );
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: VeloraResponsive(
          mobile: Column(children: cards),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards,
          ),
        ),
      ),
      floatingActionButton: Can(
        permission: 'users.view',
        child: FloatingActionButton.extended(
          onPressed: () => Velora.nav.to(AppRoutes.users),
          icon: const Icon(Icons.people),
          label: const Text('Users'),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
