import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/order_model.dart';

// ── Listagem de encomendas ───────────────────────────────────────────────────

class OrdersFilter {
  final String? status;
  final String? search;
  final int page;

  const OrdersFilter({this.status, this.search, this.page = 1});

  OrdersFilter copyWith({String? status, String? search, int? page}) =>
      OrdersFilter(
        status: status ?? this.status,
        search: search ?? this.search,
        page: page ?? this.page,
      );
}

class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final int totalPages;
  final OrdersFilter filter;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.filter = const OrdersFilter(),
  });

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    int? totalPages,
    OrdersFilter? filter,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        total: total ?? this.total,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        filter: filter ?? this.filter,
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(const OrdersState()) {
    load();
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final response = await ApiClient().dio.post(
      ApiEndpoints.orders,
      data: jsonEncode(data),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
    await load(filter: state.filter);
    return order;
  }

  Future<OrderModel> updateOrder(String id, Map<String, dynamic> data) async {
    final response = await ApiClient().dio.put(
      ApiEndpoints.orderById(id),
      data: jsonEncode(data),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
    await load(filter: state.filter);
    return order;
  }

  Future<void> load({OrdersFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, error: null, filter: f);

    try {
      final params = <String, dynamic>{'page': f.page, 'limit': 20};
      if (f.status != null) params['status'] = f.status;
      if (f.search != null && f.search!.isNotEmpty) params['search'] = f.search;

      final response = await ApiClient().dio.get(
        ApiEndpoints.orders,
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>;

      state = state.copyWith(
        orders: (data['data'] as List)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLoading: false,
        total: pagination['total'] as int,
        page: pagination['page'] as int,
        totalPages: pagination['totalPages'] as int,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    }
  }

  Future<void> refresh() => load(filter: state.filter);

  void setFilter(OrdersFilter filter) => load(filter: filter);
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(
  (_) => OrdersNotifier(),
);

// ── Detalhe de uma encomenda ─────────────────────────────────────────────────

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, id) async {
  final response =
      await ApiClient().dio.get(ApiEndpoints.orderById(id));
  return OrderModel.fromJson(response.data as Map<String, dynamic>);
});

final orderHistoryProvider =
    FutureProvider.family<List<StatusHistoryEntry>, String>((ref, id) async {
  final response =
      await ApiClient().dio.get(ApiEndpoints.orderHistory(id));
  return (response.data as List)
      .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Ações ────────────────────────────────────────────────────────────────────

Future<OrderModel> createOrder(Map<String, dynamic> data) async {
  final response = await ApiClient().dio.post(
    ApiEndpoints.orders,
    data: jsonEncode(data),
    options: Options(headers: {'Content-Type': 'application/json'}),
  );
  return OrderModel.fromJson(response.data as Map<String, dynamic>);
}

Future<void> updateOrderStatus(
    String id, String status, String? notes) async {
  await ApiClient().dio.patch(
    ApiEndpoints.orderStatus(id),
    data: {'status': status, if (notes != null) 'notes': notes},
  );
}
