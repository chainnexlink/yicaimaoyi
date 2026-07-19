import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/certification_repository.dart';
import '../../data/models/certification_model.dart';

/// CertificationRepository Provider
final certificationRepositoryProvider = Provider<CertificationRepository>((
  ref,
) {
  return CertificationRepository(ref.read(dioProvider));
});

/// 认证列表状态
class CertificationState {
  final List<CertificationModel> certifications;
  final CertificationStats stats;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const CertificationState({
    this.certifications = const [],
    this.stats = const CertificationStats(),
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  CertificationState copyWith({
    List<CertificationModel>? certifications,
    CertificationStats? stats,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return CertificationState(
      certifications: certifications ?? this.certifications,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  bool get hasApproved => certifications.any((c) => c.status == 'APPROVED');
}

/// 认证状态 Provider
final certificationProvider =
    StateNotifierProvider<CertificationNotifier, CertificationState>((ref) {
      return CertificationNotifier(ref.read(certificationRepositoryProvider));
    });

class CertificationNotifier extends StateNotifier<CertificationState> {
  final CertificationRepository _repository;

  CertificationNotifier(this._repository) : super(const CertificationState());

  Future<void> loadCertifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final certs = await _repository.getCertifications();
      final stats = await _repository.getStats();
      state = state.copyWith(
        certifications: certs,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitCertification(Map<String, dynamic> certData) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _repository.submitCertification(certData);
      await loadCertifications();
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  Future<String> uploadFile(String filePath, String fileName) async {
    return _repository.uploadCertFile(filePath, fileName);
  }
}
