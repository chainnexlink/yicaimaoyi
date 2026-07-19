import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/inquiry_repository.dart';
import '../../data/models/inquiry_model.dart';

class InquiryListState {
  final List<InquiryModel> inquiries;
  final bool isLoading;
  final String? error;

  const InquiryListState({
    this.inquiries = const [],
    this.isLoading = false,
    this.error,
  });

  InquiryListState copyWith({
    List<InquiryModel>? inquiries,
    bool? isLoading,
    String? error,
  }) {
    return InquiryListState(
      inquiries: inquiries ?? this.inquiries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository(ref.read(dioProvider));
});

final inquiryListProvider =
    StateNotifierProvider<InquiryListNotifier, InquiryListState>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      final userType = ref.watch(currentUserTypeProvider);
      return InquiryListNotifier(
        ref.read(inquiryRepositoryProvider),
        userId: userId,
        userType: userType,
      );
    });

class InquiryListNotifier extends StateNotifier<InquiryListState> {
  final InquiryRepository _repository;
  final int userId;
  final String userType;

  InquiryListNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const InquiryListState());

  bool get _isBuyer => userType != 'SUPPLIER';

  Future<void> loadInquiries({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = _isBuyer
          ? await _repository.getInquiriesByBuyer(userId, status: status)
          : await _repository.getOpenInquiries();
      state = state.copyWith(inquiries: result.content, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createInquiry(Map<String, dynamic> data) async {
    try {
      await _repository.createInquiry(userId, data);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => loadInquiries();
}
