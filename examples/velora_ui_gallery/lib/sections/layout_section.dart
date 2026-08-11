import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

/// Showcases velora_ui's Layer 4 layout/display components:
/// [VeloraAvatar], [VeloraListTile], [VeloraSectionHeader], [VeloraDivider],
/// and [VeloraProgress].
class LayoutSection extends StatelessWidget {
  /// Creates the layout-components showcase section.
  const LayoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VeloraSectionHeader(
          title: 'Section header',
          subtitle: 'A titled header with an optional trailing action',
          action: TextButton(onPressed: () {}, child: const Text('See all')),
        ),
        SizedBox(height: tokens.spacingSm),
        const VeloraSectionHeader(
          title: 'Avatars',
          subtitle: 'Photo, initials, and icon fallback, in that order',
        ),
        Row(
          children: [
            const VeloraAvatar(
              image: NetworkImage('https://i.pravatar.cc/150?img=5'),
              name: 'Grace Hopper',
              size: 48,
            ),
            SizedBox(width: tokens.spacingMd),
            const VeloraAvatar(name: 'Ada Lovelace', size: 48),
            SizedBox(width: tokens.spacingMd),
            const VeloraAvatar(size: 48),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'List tiles',
          subtitle: 'Leading avatar/icon, subtitle, and trailing content',
        ),
        VeloraCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              VeloraListTile(
                leading: const VeloraAvatar(name: 'Grace Hopper', size: 40),
                title: 'Grace Hopper',
                subtitle: 'Rear Admiral, US Navy',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const VeloraDivider(indent: 16, endIndent: 16),
              VeloraListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: 'Notifications',
                subtitle: 'Manage push and email alerts',
                trailing: const VeloraBadge(
                  label: '3',
                  status: VeloraStatus.info,
                  style: VeloraBadgeStyle.solid,
                ),
                onTap: () {},
              ),
              const VeloraDivider(indent: 16, endIndent: 16),
              const VeloraListTile(
                leading: Icon(Icons.info_outline),
                title: 'App version',
                subtitle: '1.0.0+1',
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Dividers',
          subtitle: 'Horizontal and vertical hairlines',
        ),
        const VeloraDivider(),
        SizedBox(height: tokens.spacingSm),
        SizedBox(
          height: 32,
          child: Row(
            children: [
              const Text('Left'),
              SizedBox(width: tokens.spacingSm),
              const VeloraDivider(vertical: true),
              SizedBox(width: tokens.spacingSm),
              const Text('Right'),
            ],
          ),
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Progress',
          subtitle: 'Linear and circular, determinate and indeterminate',
        ),
        const VeloraProgress.linear(value: 0.65),
        SizedBox(height: tokens.spacingSm),
        const VeloraProgress.linear(),
        SizedBox(height: tokens.spacingMd),
        Row(
          children: [
            const VeloraProgress.circular(value: 0.4),
            SizedBox(width: tokens.spacingLg),
            const VeloraProgress.circular(),
          ],
        ),
      ],
    );
  }
}
