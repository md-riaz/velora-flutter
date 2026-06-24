import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velora/velora.dart';

import '../../../routes/app_routes.dart';
import '../users_controller.dart';

class UsersIndexPage extends GetView<UsersController> {
  const UsersIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Obx(
        () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.users.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text(user.email),
              onTap: () => Velora.nav.to(AppRoutes.usersShow, arguments: user),
              trailing: Wrap(
                children: [
                  Can(
                    permission: 'users.update',
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Velora.nav.to(AppRoutes.usersEdit, arguments: user),
                    ),
                  ),
                  Can(
                    permission: 'users.delete',
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => controller.destroy(user.id),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Can(
        permission: 'users.create',
        child: FloatingActionButton(
          onPressed: () => Velora.nav.to(AppRoutes.usersCreate),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
