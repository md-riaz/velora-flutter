/// Metadata and source for a source-owned application template.
class VeloraTemplate {
  final String id;
  final String title;
  final String description;
  final Map<String, String> responsiveBehavior;
  final List<String> requiredPackages;
  final List<String> requiredComponents;
  final List<String> slots;
  final List<String> stateAssumptions;
  final List<String> states;
  final List<String> accessibilityNotes;
  final bool sourceOwned;

  const VeloraTemplate(this.id, this.title, this.description, this.slots)
    : responsiveBehavior = const {
        'phone': 'Scrollable single column.',
        'tablet': 'Centered content with flexible width.',
        'desktop': 'Centered content with flexible width.',
        'web': 'Centered content with flexible width.',
      },
      requiredPackages = const ['flutter'],
      requiredComponents = const [],
      stateAssumptions = const [
        'The caller owns state and actions and supplies the appropriate state UI.',
      ],
      states = const ['loading', 'empty', 'error', 'success'],
      accessibilityNotes = const [
        'Provide accessible labels for supplied controls.',
      ],
      sourceOwned = true;

  String get file => 'lib/app/templates/${id.replaceAll('-', '_')}.dart';
  List<String> get files => [file];

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'responsiveBehavior': responsiveBehavior,
    'requiredPackages': requiredPackages,
    'requiredComponents': requiredComponents,
    'slots': slots,
    'files': files,
    'stateAssumptions': stateAssumptions,
    'states': states,
    'accessibilityNotes': accessibilityNotes,
    'sourceOwned': sourceOwned,
  };

  /// A controlled page shell: callers supply content for each UI state.
  String get source {
    final name = id
        .split('-')
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join();
    final parameters = slots.map((slot) => 'required this.$slot').join(', ');
    final fields = slots.map((slot) => '  final Widget $slot;').join('\n');
    final children = slots.join(', ');
    return '''import 'package:flutter/material.dart';

class ${name}Page extends StatelessWidget {
  const ${name}Page({super.key, $parameters});

$fields

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('$title')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [$children],
        ),
      ),
    ),
  );
}
''';
  }
}

const veloraTemplates = <VeloraTemplate>[
  VeloraTemplate(
    'dashboard-shell',
    'Dashboard',
    'A dashboard shell for app content.',
    ['navigation', 'content'],
  ),
  VeloraTemplate(
    'crud-list',
    'List',
    'A page for listing and managing records.',
    ['actions', 'content'],
  ),
  VeloraTemplate(
    'crud-form',
    'Form',
    'A page for creating or editing a record.',
    ['form', 'actions'],
  ),
  VeloraTemplate(
    'detail-page',
    'Detail',
    'A page for displaying record details.',
    ['content', 'actions'],
  ),
  VeloraTemplate(
    'settings-page',
    'Settings',
    'A page for application settings.',
    ['settings'],
  ),
  VeloraTemplate(
    'auth-flow',
    'Authentication',
    'A page for an authentication flow.',
    ['form', 'actions'],
  ),
  VeloraTemplate('wizard', 'Wizard', 'A page for a multi-step flow.', [
    'progress',
    'content',
    'actions',
  ]),
];
