import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/supplier_center_repository.dart';
import '../../data/models/supplier_product_model.dart';

// ============ Repository Provider ============

final supplierCenterRepositoryProvider = Provider<SupplierCenterRepository>((
  ref,
) {
  return SupplierCenterRepository(ref.read(dioProvider));
});

// ============ 产品管理 State ============

class SupplierProductsState {
  final List<SupplierProductModel> products;
  final bool isLoading;
  final String? error;
  final String? statusFilter;

  const SupplierProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
  });

  SupplierProductsState copyWith({
    List<SupplierProductModel>? products,
    bool? isLoading,
    String? error,
    String? statusFilter,
    bool clearError = false,
  }) {
    return SupplierProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final supplierProductsProvider =
    StateNotifierProvider<SupplierProductsNotifier, SupplierProductsState>((
      ref,
    ) {
      return SupplierProductsNotifier(
        ref.read(supplierCenterRepositoryProvider),
      );
    });

class SupplierProductsNotifier extends StateNotifier<SupplierProductsState> {
  final SupplierCenterRepository _repository;
  SupplierProductsNotifier(this._repository)
    : super(const SupplierProductsState());

  Future<void> loadProducts({String? status}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      statusFilter: status,
    );
    try {
      final result = await _repository.getProducts(status: status);
      state = state.copyWith(products: result.content, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repository.deleteProduct(id);
      state = state.copyWith(
        products: state.products.where((p) => p.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleProductStatus(int id) async {
    final product = state.products.firstWhere((p) => p.id == id);
    final newStatus = product.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    try {
      await _repository.updateProductStatus(id, newStatus);
      state = state.copyWith(
        products: state.products.map((p) {
          if (p.id == id) return p.copyWith(status: newStatus);
          return p;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => loadProducts(status: state.statusFilter);
}

// ============ 供应商概览 State ============

class SupplierDashboardState {
  final SupplierDashboardStats? stats;
  final bool isLoading;
  final String? error;

  const SupplierDashboardState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  SupplierDashboardState copyWith({
    SupplierDashboardStats? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SupplierDashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final supplierDashboardProvider =
    StateNotifierProvider<SupplierDashboardNotifier, SupplierDashboardState>((
      ref,
    ) {
      return SupplierDashboardNotifier(
        ref.read(supplierCenterRepositoryProvider),
      );
    });

class SupplierDashboardNotifier extends StateNotifier<SupplierDashboardState> {
  final SupplierCenterRepository _repository;
  SupplierDashboardNotifier(this._repository)
    : super(const SupplierDashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final stats = await _repository.getDashboardStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ============ 供应商入驻 State ============

class SupplierApplyState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? applicationStatus; // PENDING, APPROVED, REJECTED, null
  final bool submitSuccess;

  const SupplierApplyState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.applicationStatus,
    this.submitSuccess = false,
  });

  SupplierApplyState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? applicationStatus,
    bool? submitSuccess,
    bool clearError = false,
  }) {
    return SupplierApplyState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}

final supplierApplyProvider =
    StateNotifierProvider<SupplierApplyNotifier, SupplierApplyState>((ref) {
      return SupplierApplyNotifier(ref.read(supplierCenterRepositoryProvider));
    });

class SupplierApplyNotifier extends StateNotifier<SupplierApplyState> {
  final SupplierCenterRepository _repository;
  SupplierApplyNotifier(this._repository) : super(const SupplierApplyState());

  Future<void> checkStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getApplicationStatus();
      state = state.copyWith(
        isLoading: false,
        applicationStatus: result['status'] as String?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitApplication(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.submitApplication(data);
      state = state.copyWith(
        isSubmitting: false,
        submitSuccess: true,
        applicationStatus: 'PENDING',
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}
