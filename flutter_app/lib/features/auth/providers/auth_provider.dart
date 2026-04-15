import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_storage.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});
  bool get isAuthenticated => user != null;
  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) { _loadFromStorage(); }

  Future<void> _loadFromStorage() async {
    try {
      final token = await AuthStorage.getAccessToken();
      if (token == null) return;
      ApiClient().setToken(token); // repor token no cliente
      final userData = await AuthStorage.getUser();
      if (userData['id'] == null) return;
      state = AuthState(
        user: UserModel(id: userData['id']!, name: userData['name'] ?? '',
            email: userData['email'] ?? '', role: userData['role'] ?? 'VIEWER'),
      );
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.login,
        data: jsonEncode({'login': email, 'password': password}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      // Guardar token imediatamente no cliente HTTP
      ApiClient().setToken(accessToken);

      await Future.wait([
        AuthStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken),
        AuthStorage.saveUser(id: user.id, name: user.name, email: user.email ?? '', role: user.role),
      ]);

      state = AuthState(user: user);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['error'] ?? e.response!.data['message'] ?? 'Erro desconhecido')
          : 'Erro ao ligar ao servidor: ${e.message}';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro inesperado: $e');
    }
  }

  Future<void> logout() async {
    try { await ApiClient().dio.post(ApiEndpoints.logout); } catch (_) {}
    ApiClient().clearToken();
    await AuthStorage.clear();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((_) => AuthNotifier());
