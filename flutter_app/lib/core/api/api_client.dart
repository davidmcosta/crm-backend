import 'package:dio/dio.dart';
import '../auth/auth_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _token; // token em memória — disponível instantaneamente

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor(this));
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
}

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  final ApiClient client;
  _AuthInterceptor(this.client);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Usa o token em memória primeiro (imediato), fallback para storage
    final token = client._token ?? await AuthStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await AuthStorage.getRefreshToken();

      if (refreshToken == null) {
        client.clearToken();
        await AuthStorage.clear();
        return handler.next(err);
      }

      try {
        final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
        final response = await dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        final newToken = response.data['accessToken'] as String;
        client.setToken(newToken);
        await AuthStorage.updateAccessToken(newToken);

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await ApiClient().dio.fetch(opts);
        return handler.resolve(retryResponse);
      } catch (_) {
        client.clearToken();
        await AuthStorage.clear();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

String extractErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data.containsKey('error')) return data['error'] as String;
  if (data is Map && data.containsKey('message')) return data['message'] as String;
  return 'Ocorreu um erro inesperado. Tenta novamente.';
}
