import 'package:dio/dio.dart';
import '../auth/auth_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor());
  }
}

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthStorage.getAccessToken();
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
    // Se o token expirou (401), tenta renovar automaticamente
    if (err.response?.statusCode == 401) {
      final refreshToken = await AuthStorage.getRefreshToken();

      if (refreshToken == null) {
        await AuthStorage.clear();
        return handler.next(err);
      }

      try {
        final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
        final response = await dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        await AuthStorage.updateAccessToken(newAccessToken);

        // Repete o pedido original com o novo token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await ApiClient().dio.fetch(opts);
        return handler.resolve(retryResponse);
      } catch (_) {
        await AuthStorage.clear();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

// Helper para extrair a mensagem de erro da API
String extractErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data.containsKey('error')) {
    return data['error'] as String;
  }
  if (data is Map && data.containsKey('message')) {
    return data['message'] as String;
  }
  return 'Ocorreu um erro inesperado. Tenta novamente.';
}
