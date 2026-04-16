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

/// Extrai mensagem amigável de qualquer exceção (DioException ou genérica).
String friendlyError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = (data['error'] ?? data['message'])?.toString() ?? '';
      if (msg.isNotEmpty) return msg;
    }
    switch (e.response?.statusCode) {
      case 400: return 'Pedido inválido. Verifique os dados introduzidos.';
      case 401: return 'Sessão expirada. Por favor inicie sessão novamente.';
      case 403: return 'Sem permissão para realizar esta operação.';
      case 404: return 'Registo não encontrado.';
      case 409: return 'Conflito de dados. Verifique as informações introduzidas.';
      case 500: return 'Erro interno do servidor. Tente mais tarde.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Tempo de resposta excedido. Verifique a ligação à rede.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sem ligação ao servidor. Verifique a rede e tente novamente.';
    }
    return 'Erro de ligação. Verifique a rede e tente novamente.';
  }
  return e.toString().replaceAll('Exception: ', '');
}

/// Mantido por compatibilidade — usa friendlyError internamente.
String extractErrorMessage(DioException e) => friendlyError(e);
