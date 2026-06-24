import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../user_model.dart';

class UserShowPage extends StatelessWidget {
  const UserShowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.arguments as UserModel;
    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
        ),
      ),
    );
  }
}
