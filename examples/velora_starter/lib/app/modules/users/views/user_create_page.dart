import 'package:flutter/material.dart';

import 'package:velora/velora.dart';

import '../users_controller.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({super.key});

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  final name = TextEditingController();
  final email = TextEditingController();

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
      appBar: AppBar(title: const Text('Create user')),
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
                await controller.create(name.text, email.text);
                Velora.nav.back();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
