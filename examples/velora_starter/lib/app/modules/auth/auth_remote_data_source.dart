import 'package:velora/velora.dart';

abstract class StarterAuthRemoteDataSource {
  Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> credentials,
  );

  Future<ApiResponse<Map<String, dynamic>>> me(String token);

  Future<ApiResponse<void>> logout(String token);
}

class MockStarterAuthRemoteDataSource implements StarterAuthRemoteDataSource {
  static const _demoPassword = 'password';
  static const _demoToken = 'demo-token';

  @override
  Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> credentials,
  ) async {
    final email = credentials['email']?.toString() ?? '';
    final password = credentials['password']?.toString() ?? '';
    if (email.trim().isEmpty || password != _demoPassword) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'The provided credentials are incorrect.',
        statusCode: 422,
        errors: const {
          'email': ['These credentials do not match our records.'],
        },
      );
    }

    return ApiResponse.fromJson(
      _loginPayload(email),
      parser: (value) => Map<String, dynamic>.from(value as Map),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> me(String token) async {
    if (token != _demoToken) {
      return const ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unauthenticated.',
        statusCode: 401,
      );
    }

    return ApiResponse.fromJson({
      'success': true,
      'data': {'user': _adminUser},
    }, parser: (value) => Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<ApiResponse<void>> logout(String token) async {
    return const ApiResponse(success: true, message: 'Logged out');
  }

  Map<String, dynamic> _loginPayload(String email) {
    return {
      'success': true,
      'message': 'Authenticated',
      'data': {
        'token': _demoToken,
        'token_type': 'Bearer',
        'user': {..._adminUser, 'email': email},
      },
    };
  }

  static const Map<String, dynamic> _adminUser = {
    'id': 1,
    'name': 'Admin User',
    'email': 'admin@example.com',
    'roles': ['admin'],
    'permissions': [
      'users.view',
      'users.create',
      'users.update',
      'users.delete',
      'notifications.view',
    ],
    'features': ['users', 'notifications'],
  };
}
