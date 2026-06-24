import 'package:get/get.dart';

abstract class VeloraFormController extends GetxController {
  final RxMap<String, List<String>> errors = <String, List<String>>{}.obs;

  void setErrors(Map<String, List<String>> newErrors) {
    errors.assignAll(newErrors);
  }

  String? firstError(String field) => errors[field]?.firstOrNull;

  void clearErrors() => errors.clear();
}
