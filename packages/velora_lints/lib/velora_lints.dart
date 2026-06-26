import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/ever_in_widget_build.dart';
import 'src/rules/obx_missing_reactive_read.dart';
import 'src/rules/obx_with_no_reads.dart';
import 'src/rules/rx_in_build_without_obx.dart';

PluginBase createPlugin() => _VeloraLints();

class _VeloraLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        ObxMissingReactiveRead(),
        ObxWithNoReads(),
        EverInWidgetBuild(),
        RxInBuildWithoutObx(),
      ];
}
