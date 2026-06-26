import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/ever_in_widget_build.dart';
import 'src/rules/obx_missing_reactive_read.dart';

PluginBase createPlugin() => _VeloraLints();

class _VeloraLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        ObxMissingReactiveRead(),
        EverInWidgetBuild(),
      ];
}
