import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────

class UserItem {
  final String  id;
  final String  name;
  final String? email;
  final String? username;
  final String  role;
  final bool    isActive;
  final bool    isMaster;
  final DateTime createdAt;

  const UserItem({
    required this.id,
    required this.name,
    this.email,
    this.username,
    required this.role,
    required this.isActive,
    required this.isMaster,
    required this.createdAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> j) => UserItem(
        id:        j['id']       as String,
        name:      j['name']     as String,
        email:     j['email']    as String?,
        username:  j['username'] as String?,
        role:      j['role']     as String,
        isActive:  j['isActive'] as bool? ?? true,
        isMaster:  j['isMaster'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  String get roleLabel {
    switch (role) {
      case 'ADMIN':    return 'Admin';
      case 'MANAGER':  return 'Gestor';
      case 'OPERATOR': return 'Operador';
      default:         return 'Visualizador';
    }
  }
}

// ── Estado ────────────────────────────────────────────────────────────────────

class UsersState {
  final List<UserItem> users;
  final bool isLoading;
  final String? error;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UsersState copyWith({
    List<UserItem>? users,
    bool? isLoading,
    String? error,
  }) =>
      UsersState(
        users:     users     ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class UsersNotifier extends StateNotifier<UsersState> {
  UsersNotifier() : super(const UsersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.users);
      final data = response.data;
      final list = (data is List
              ? data
              : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [])
          .map((e) => UserItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = UsersState(users: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyError(e));
    }
  }

  Future<void> changeRole(String userId, String newRole) async {
    await ApiClient().dio.patch(
      ApiEndpoints.userRole(userId),
      data: {'role': newRole},
    );
    await load();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await ApiClient().dio.put(
      ApiEndpoints.userById(userId),
      data: data,
    );
    await load();
  }

  Future<void> deactivate(String userId) async {
    await ApiClient().dio.delete(
      ApiEndpoints.userById(userId),
      data: <String, dynamic>{},
    );
    await load();
  }
}

final usersProvider =
    StateNotifierProvider<UsersNotifier, UsersState>((_) => UsersNotifier());
