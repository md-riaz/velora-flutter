import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velora/velora.dart';

import '../user_model.dart';
import '../users_controller.dart';

class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  late final UserModel user = Get.arguments as UserModel;
  late final name = TextEditingController(text: user.name);
  late final email = TextEditingController(text: user.email);

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit user')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await controller.saveUser(user.id, name.text, email.text);
                Velora.nav.back();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
