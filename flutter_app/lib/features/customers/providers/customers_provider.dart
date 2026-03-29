import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/customer_model.dart';

class CustomersState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;
  final int total;
  final String? search;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.search,
  });

  CustomersState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? error,
    int? total,
    String? search,
  }) =>
      CustomersState(
        customers: customers ?? this.customers,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        total: total ?? this.total,
        search: search ?? this.search,
      );
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  CustomersNotifier() : super(const CustomersState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null, search: search);

    try {
      final params = <String, dynamic>{'limit': 100};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await ApiClient().dio.get(
        ApiEndpoints.customers,
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        customers: (data['data'] as List)
            .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLoading: false,
        total: (data['pagination'] as Map)['total'] as int,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    }
  }

  Future<void> refresh() => load(search: state.search);
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>(
  (_) => CustomersNotifier(),
);

final customerDetailProvider =
    FutureProvider.family<CustomerModel, String>((ref, id) async {
  final response =
      await ApiClient().dio.get(ApiEndpoints.customerById(id));
  return CustomerModel.fromJson(response.data as Map<String, dynamic>);
});
