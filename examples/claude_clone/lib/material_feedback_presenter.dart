import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

class MaterialFeedbackPresenter implements FeedbackPresenter {
  const MaterialFeedbackPresenter();
  void _show(String message) {
    final context = Get.context;
    if (context != null)
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void success(String message) => _show(message);
  @override
  void error(String message) => _show(message);
  @override
  Future<bool> confirm(ConfirmationRequest request) async {
    final context = Get.context;
    if (context == null) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(request.title),
            content: Text(request.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(request.cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(request.confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}
