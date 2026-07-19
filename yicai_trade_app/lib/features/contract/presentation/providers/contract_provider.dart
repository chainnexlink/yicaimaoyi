import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/contract_repository.dart';
import '../../data/models/contract_model.dart';

class ContractListState {
  final List<ContractModel> contracts;
  final bool isLoading;
  final String? error;

  const ContractListState({
    this.contracts = const [],
    this.isLoading = false,
    this.error,
  });

  ContractListState copyWith({
    List<ContractModel>? contracts,
    bool? isLoading,
    String? error,
  }) {
    return ContractListState(
      contracts: contracts ?? this.contracts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  return ContractRepository(ref.read(dioProvider));
});

final contractListProvider =
    StateNotifierProvider<ContractListNotifier, ContractListState>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      final userType = ref.watch(currentUserTypeProvider);
      return ContractListNotifier(
        ref.read(contractRepositoryProvider),
        userId: userId,
        userType: userType,
      );
    });

class ContractListNotifier extends StateNotifier<ContractListState> {
  final ContractRepository _repository;
  final int userId;
  final String userType;

  ContractListNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const ContractListState());

  bool get _isBuyer => userType != 'SUPPLIER';

  Future<void> loadContracts({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = _isBuyer
          ? await _repository.getContractsByBuyer(userId, status: status)
          : await _repository.getContractsBySupplier(userId, status: status);
      state = state.copyWith(contracts: result.content, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signContract(int contractId) async {
    try {
      if (_isBuyer) {
        await _repository.signContractAsBuyer(contractId, userId);
      } else {
        await _repository.signContractAsSupplier(contractId, userId);
      }
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => loadContracts();
}
