import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velora/velora.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = Velora.notify.unreadCount.value;
      if (count == 0) return const SizedBox.shrink();

      return Positioned(
        right: 0,
        top: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(999),
          ),
          constraints: const BoxConstraints(minWidth: 18),
          child: Text(
            count > 99 ? '99+' : '$count',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onError,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }
}
