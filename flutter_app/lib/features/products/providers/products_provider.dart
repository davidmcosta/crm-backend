import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/product_model.dart';

// ── Lista de produtos ─────────────────────────────────────────────────────────

final productsProvider = FutureProvider.family<List<ProductModel>, String?>((ref, category) async {
  final params = <String, dynamic>{ 'active': 'true' };
  if (category != null && category.isNotEmpty) params['category'] = category;
  final response = await ApiClient().dio.get(ApiEndpoints.products, queryParameters: params);
  return (response.data as List)
      .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Todos os produtos (para o picker)
final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final response = await ApiClient().dio.get(ApiEndpoints.products, queryParameters: {'active': 'true'});
  return (response.data as List)
      .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Categorias ────────────────────────────────────────────────────────────────

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final response = await ApiClient().dio.get(ApiEndpoints.productCategories);
  return (response.data as List).cast<String>();
});

// ── Produto individual ────────────────────────────────────────────────────────

final productDetailProvider = FutureProvider.family<ProductModel, String>((ref, id) async {
  final response = await ApiClient().dio.get(ApiEndpoints.productById(id));
  return ProductModel.fromJson(response.data as Map<String, dynamic>);
});

// ── Estado do ecrã de gestão ─────────────────────────────────────────────────

class ProductsState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  ProductsState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    bool clearCategory = false,
    bool clearError = false,
  }) => ProductsState(
        products:         products         ?? this.products,
        isLoading:        isLoading        ?? this.isLoading,
        error:            clearError       ? null : (error ?? this.error),
        selectedCategory: clearCategory    ? null : (selectedCategory ?? this.selectedCategory),
      );
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier() : super(const ProductsState());

  Future<void> load({String? category}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{ 'active': 'true' };
      if (category != null && category.isNotEmpty) params['category'] = category;
      final res = await ApiClient().dio.get(ApiEndpoints.products, queryParameters: params);
      final products = (res.data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        products: products,
        isLoading: false,
        selectedCategory: category,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyError(e));
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await ApiClient().dio.post(ApiEndpoints.products, data: data);
    await load(category: state.selectedCategory);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await ApiClient().dio.put(ApiEndpoints.productById(id), data: data);
    await load(category: state.selectedCategory);
  }

  Future<void> delete(String id) async {
    await ApiClient().dio.delete(ApiEndpoints.productById(id));
    await load(category: state.selectedCategory);
  }
}

final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});
