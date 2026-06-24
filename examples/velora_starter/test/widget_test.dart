import 'package:flutter_test/flutter_test.dart';
import 'package:velora_starter/app/modules/users/users_remote_data_source.dart';
import 'package:velora_starter/app/modules/users/users_repository.dart';

void main() {
  test('mock users repository creates and lists users', () async {
    final repository = UsersRepositoryImpl(MockUsersRemoteDataSource());

    await repository.store({'name': 'Jane User', 'email': 'jane@example.com'});
    final users = await repository.index();

    expect(users.map((user) => user.email), contains('jane@example.com'));
  });
}
