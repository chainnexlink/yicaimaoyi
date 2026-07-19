import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/supplier_repository.dart';
import '../../data/models/supplier_model.dart';

class SupplierListState {
  final List<SupplierModel> suppliers;
  final bool isLoading;
  final String? error;
  final String? searchKeyword;
  final String? selectedCategory;
  final String sortBy;

  const SupplierListState({
    this.suppliers = const [],
    this.isLoading = false,
    this.error,
    this.searchKeyword,
    this.selectedCategory,
    this.sortBy = 'comprehensive',
  });

  SupplierListState copyWith({
    List<SupplierModel>? suppliers,
    bool? isLoading,
    String? error,
    String? searchKeyword,
    String? selectedCategory,
    String? sortBy,
  }) {
    return SupplierListState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository(ref.read(dioProvider));
});

final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, SupplierListState>((ref) {
      return SupplierListNotifier(ref.read(supplierRepositoryProvider));
    });

class SupplierListNotifier extends StateNotifier<SupplierListState> {
  final SupplierRepository _repository;

  SupplierListNotifier(this._repository) : super(const SupplierListState());

  Future<void> loadSuppliers({
    String? keyword,
    String? category,
    String? sortBy,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchKeyword: keyword,
      selectedCategory: category,
      sortBy: sortBy,
    );
    try {
      final result = await _repository.getSuppliers(
        keyword: keyword,
        category: category,
        sortBy: sortBy,
      );
      state = state.copyWith(suppliers: result.content, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String keyword) => loadSuppliers(
    keyword: keyword,
    category: state.selectedCategory,
    sortBy: state.sortBy,
  );

  Future<void> filterByCategory(String? category) => loadSuppliers(
    keyword: state.searchKeyword,
    category: category,
    sortBy: state.sortBy,
  );

  Future<void> refresh() => loadSuppliers(
    keyword: state.searchKeyword,
    category: state.selectedCategory,
    sortBy: state.sortBy,
  );
}
