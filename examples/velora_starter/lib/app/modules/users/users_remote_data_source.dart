import 'package:velora/velora.dart';

import 'user_model.dart';

abstract class UsersRemoteDataSource
    implements VeloraRemoteDataSource<UserModel> {
  Future<PaginatedData<UserModel>> paginate({int page = 1, int perPage = 15});
}

class MockUsersRemoteDataSource implements UsersRemoteDataSource {
  final List<Map<String, dynamic>> _users = [
    {'id': 1, 'name': 'Admin User', 'email': 'admin@example.com'},
    {'id': 2, 'name': 'Manager User', 'email': 'manager@example.com'},
  ];
  int _nextId = 3;

  @override
  Future<List<UserModel>> index() async {
    final response = ApiResponse.fromJson(
      _collectionPayload(_users),
      parser: (value) => (value as List)
          .map(
            (item) =>
                UserModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
    return response.data ?? const [];
  }

  @override
  Future<PaginatedData<UserModel>> paginate({
    int page = 1,
    int perPage = 15,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 15 : perPage;
    final start = (safePage - 1) * safePerPage;
    final items = start >= _users.length
        ? <Map<String, dynamic>>[]
        : _users.skip(start).take(safePerPage).toList();
    return PaginatedData.fromJson(
      _paginatedPayload(
        items,
        page: safePage,
        perPage: safePerPage,
        total: _users.length,
      ),
      (value) => UserModel.fromJson(Map<String, dynamic>.from(value as Map)),
    );
  }

  @override
  Future<UserModel> show(int id) async {
    final response = ApiResponse.fromJson(
      _resourcePayload(_findUser(id)),
      parser: (value) =>
          UserModel.fromJson(Map<String, dynamic>.from(value as Map)),
    );
    return response.data!;
  }

  @override
  Future<UserModel> store(Map<String, dynamic> data) async {
    final user = {
      'id': _nextId++,
      'name': data['name']?.toString() ?? '',
      'email': data['email']?.toString() ?? '',
    };
    _users.add(user);
    final response = ApiResponse.fromJson(
      _resourcePayload(user, message: 'User created'),
      parser: (value) =>
          UserModel.fromJson(Map<String, dynamic>.from(value as Map)),
    );
    return response.data!;
  }

  @override
  Future<UserModel> update(int id, Map<String, dynamic> data) async {
    final index = _users.indexWhere((user) => user['id'] == id);
    if (index < 0) throw StateError('User not found.');
    final user = {
      'id': id,
      'name': data['name']?.toString() ?? _users[index]['name'],
      'email': data['email']?.toString() ?? _users[index]['email'],
    };
    _users[index] = user;
    final response = ApiResponse.fromJson(
      _resourcePayload(user, message: 'User updated'),
      parser: (value) =>
          UserModel.fromJson(Map<String, dynamic>.from(value as Map)),
    );
    return response.data!;
  }

  @override
  Future<void> destroy(int id) async {
    _users.removeWhere((user) => user['id'] == id);
  }

  Map<String, dynamic> _findUser(int id) {
    return _users.firstWhere((user) => user['id'] == id);
  }

  Map<String, dynamic> _collectionPayload(List<Map<String, dynamic>> users) {
    return {'success': true, 'data': users};
  }

  Map<String, dynamic> _resourcePayload(
    Map<String, dynamic> user, {
    String? message,
  }) {
    return {'success': true, 'message': ?message, 'data': user};
  }

  Map<String, dynamic> _paginatedPayload(
    List<Map<String, dynamic>> users, {
    required int page,
    required int perPage,
    required int total,
  }) {
    return {
      'data': users,
      'meta': {
        'current_page': page,
        'last_page': (total / perPage).ceil().clamp(1, 1 << 31),
        'per_page': perPage,
        'total': total,
      },
    };
  }
}
