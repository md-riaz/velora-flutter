import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

/// Showcases velora_ui's Layer 2 "display" components: [VeloraButton],
/// [VeloraCard], [VeloraBadge], [VeloraChip], [VeloraAlert],
/// [VeloraEmptyState], and [VeloraSkeleton].
///
/// The chip row and the dismissible alert are wired to local state via
/// `setState` so they respond to real taps, not just static examples.
class DisplaySection extends StatefulWidget {
  /// Creates the display-components showcase section.
  const DisplaySection({super.key});

  @override
  State<DisplaySection> createState() => _DisplaySectionState();
}

class _DisplaySectionState extends State<DisplaySection> {
  final Set<String> _selectedTags = {'Design'};
  bool _showDismissibleAlert = true;

  static const _allTags = ['Design', 'Engineering', 'Product', 'Marketing'];
  static const _initialRemovableChips = ['Removable', 'Dismiss me'];
  final List<String> _removableChips = [..._initialRemovableChips];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VeloraSectionHeader(
          title: 'Buttons',
          subtitle: 'Every variant, size, an icon, and a loading state',
        ),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: [
            VeloraButton(label: 'Primary', onPressed: () {}),
            VeloraButton(
              label: 'Secondary',
              onPressed: () {},
              variant: VeloraButtonVariant.secondary,
            ),
            VeloraButton(
              label: 'Outline',
              onPressed: () {},
              variant: VeloraButtonVariant.outline,
            ),
            VeloraButton(
              label: 'Ghost',
              onPressed: () {},
              variant: VeloraButtonVariant.ghost,
            ),
            VeloraButton(
              label: 'Danger',
              onPressed: () {},
              variant: VeloraButtonVariant.danger,
            ),
          ],
        ),
        SizedBox(height: tokens.spacingSm),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VeloraButton(
              label: 'Small',
              onPressed: () {},
              size: VeloraButtonSize.small,
            ),
            VeloraButton(label: 'Medium', onPressed: () {}),
            VeloraButton(
              label: 'Large',
              onPressed: () {},
              size: VeloraButtonSize.large,
            ),
            VeloraButton(
              label: 'With icon',
              onPressed: () {},
              icon: Icons.rocket_launch_outlined,
            ),
            const VeloraButton(
              label: 'Loading',
              onPressed: null,
              loading: true,
              variant: VeloraButtonVariant.secondary,
            ),
            const VeloraButton(label: 'Disabled', onPressed: null),
          ],
        ),
        SizedBox(height: tokens.spacingMd),
        VeloraButton(
          label: 'Full-width primary',
          onPressed: () {},
          fullWidth: true,
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Cards',
          subtitle: 'Padded, rounded surfaces — tappable or static',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: VeloraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Static card', style: textTheme.titleSmall),
                    SizedBox(height: tokens.spacingXs),
                    Text(
                      'Elevated by default, using the theme shadow token.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: tokens.spacingMd),
            Expanded(
              child: VeloraCard(
                elevated: false,
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tappable, flat card', style: textTheme.titleSmall),
                    SizedBox(height: tokens.spacingXs),
                    Text(
                      'No shadow; tap anywhere for a ripple.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Badges',
          subtitle: 'Solid and soft, across every VeloraStatus',
        ),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: const [
            VeloraBadge(
              label: 'Success',
              status: VeloraStatus.success,
              style: VeloraBadgeStyle.solid,
            ),
            VeloraBadge(
              label: 'Warning',
              status: VeloraStatus.warning,
              style: VeloraBadgeStyle.solid,
            ),
            VeloraBadge(
              label: 'Info',
              status: VeloraStatus.info,
              style: VeloraBadgeStyle.solid,
            ),
            VeloraBadge(
              label: 'Error',
              status: VeloraStatus.error,
              style: VeloraBadgeStyle.solid,
              icon: Icons.error_outline,
            ),
            VeloraBadge(label: 'Success', status: VeloraStatus.success),
            VeloraBadge(label: 'Warning', status: VeloraStatus.warning),
            VeloraBadge(label: 'Info', status: VeloraStatus.info),
            VeloraBadge(label: 'Error', status: VeloraStatus.error),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Chips',
          subtitle: 'Tap a tag to toggle it; tap × to remove',
        ),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in _allTags)
              VeloraChip(
                label: tag,
                selected: _selectedTags.contains(tag),
                onTap: () => _toggleTag(tag),
                icon: _selectedTags.contains(tag) ? Icons.check : null,
              ),
            for (final chip in _removableChips)
              VeloraChip(
                label: chip,
                onDeleted: () => setState(() => _removableChips.remove(chip)),
              ),
            if (_removableChips.isEmpty)
              VeloraButton(
                label: 'Restore chips',
                onPressed: () => setState(
                  () => _removableChips.addAll(_initialRemovableChips),
                ),
                variant: VeloraButtonVariant.ghost,
                size: VeloraButtonSize.small,
              ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Alerts',
          subtitle: 'Semantic banners for every VeloraStatus',
        ),
        Column(
          children: [
            const VeloraAlert(
              status: VeloraStatus.success,
              title: 'Saved',
              message: 'Your changes have been saved successfully.',
            ),
            SizedBox(height: tokens.spacingSm),
            const VeloraAlert(
              status: VeloraStatus.warning,
              title: 'Storage nearly full',
              message: 'You are using 92% of your available storage.',
            ),
            SizedBox(height: tokens.spacingSm),
            const VeloraAlert(
              status: VeloraStatus.info,
              message: 'A new release is available with several fixes.',
            ),
            if (_showDismissibleAlert) ...[
              SizedBox(height: tokens.spacingSm),
              VeloraAlert(
                status: VeloraStatus.error,
                title: 'Upload failed',
                message: 'Check your connection and try again.',
                onClose: () => setState(() => _showDismissibleAlert = false),
              ),
            ],
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Empty state',
          subtitle: 'A centered "nothing here yet" placeholder',
        ),
        VeloraCard(
          child: VeloraEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No messages yet',
            message: 'When you receive a message, it will show up here.',
            action: VeloraButton(
              label: 'Compose',
              onPressed: () {},
              size: VeloraButtonSize.small,
            ),
          ),
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Skeletons',
          subtitle: 'Pulsing loading placeholders',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VeloraSkeleton.circle(diameter: 40),
            SizedBox(width: tokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VeloraSkeleton.text(width: 160),
                  SizedBox(height: tokens.spacingXs),
                  const VeloraSkeleton.text(),
                  SizedBox(height: tokens.spacingXs),
                  const VeloraSkeleton(height: 80, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
