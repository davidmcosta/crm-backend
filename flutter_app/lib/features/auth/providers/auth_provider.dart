import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_storage.dart';
import '../models/user_model.dart';

// Estado da autenticação
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// Provider principal de autenticação
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadFromStorage();
  }

  // Tenta carregar sessão guardada no arranque
  Future<void> _loadFromStorage() async {
    final token = await AuthStorage.getAccessToken();
    if (token == null) return;

    final userData = await AuthStorage.getUser();
    if (userData['id'] == null) return;

    state = AuthState(
      user: UserModel(
        id: userData['id']!,
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] ?? 'VIEWER',
      ),
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await Future.wait([
        AuthStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        ),
        AuthStorage.saveUser(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
        ),
      ]);

      state = AuthState(user: user);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient().dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await AuthStorage.clear();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
