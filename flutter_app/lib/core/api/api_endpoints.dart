class ApiEndpoints {
  // Muda este URL para o endereço do teu servidor
  static const String baseUrl = 'https://crm-backend-production-65ef.up.railway.app/api';

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Encomendas
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';
  static String orderHistory(String id) => '/orders/$id/history';

  // Clientes
  static const String customers = '/customers';
  static String customerById(String id) => '/customers/$id';
  static String customerOrders(String id) => '/customers/$id/orders';

  // Utilizadores
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static String userRole(String id) => '/users/$id/role';
  static const String changePassword = '/users/me/password';

  // Produtos
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static const String productCategories = '/products/categories';

  // Configurações
  static const String settings = '/settings';

  // Estatísticas
  static const String stats = '/stats';

  // Via Verde
  static const String viaVerde = '/viaverde/calcular';
}
