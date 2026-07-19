import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/smart_match_repository.dart';
import '../../data/models/smart_match_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Repository Provider
final smartMatchRepositoryProvider = Provider<SmartMatchRepository>((ref) {
  return SmartMatchRepository(ref.read(dioProvider));
});

/// Smart match state - sessionId driven 5-step wizard
class SmartMatchState {
  final int currentStep; // 0-4
  final bool isLoading;
  final String? error;
  final int maxCompletedStep;

  /// AI thinking phase text (for loading animation)
  final String? aiThinkingText;

  // Step 1: Product matching
  final String productName;
  final String? imageUrl;
  final String? sessionId;
  final List<MatchedCategory> matchedCategories;
  final String? selectedCategoryCode;
  final String? selectedCategoryName;

  // Step 2: Cost parameters
  final List<CostParameter> costParameters;
  final Map<String, dynamic> costParameterValues;

  /// Manual override parameters (parameterCode -> manualValue)
  final Map<String, String> manualOverrides;

  // Step 3: Cost estimate
  final CostEstimateResult? costEstimate;

  // Step 4: Factory quotes
  final FactoryQuoteResult? factoryQuote;
  final int? selectedSupplierIndex;
  final String? selectedSupplierCode;

  // Step 5: FOB estimate
  final List<CostParameter> fobParameters;
  final Map<String, dynamic> fobParameterValues;
  final FobEstimateResult? fobEstimate;

  /// Raw JSON responses per step (formatted strings), key = step number
  final Map<int, String> rawResponses;

  const SmartMatchState({
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
    this.maxCompletedStep = -1,
    this.aiThinkingText,
    this.productName = '',
    this.imageUrl,
    this.sessionId,
    this.matchedCategories = const [],
    this.selectedCategoryCode,
    this.selectedCategoryName,
    this.costParameters = const [],
    this.costParameterValues = const {},
    this.manualOverrides = const {},
    this.costEstimate,
    this.factoryQuote,
    this.selectedSupplierIndex,
    this.selectedSupplierCode,
    this.fobParameters = const [],
    this.fobParameterValues = const {},
    this.fobEstimate,
    this.rawResponses = const {},
  });

  SmartMatchState copyWith({
    int? currentStep,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? maxCompletedStep,
    String? aiThinkingText,
    bool clearAiThinking = false,
    String? productName,
    String? imageUrl,
    bool clearImageUrl = false,
    String? sessionId,
    List<MatchedCategory>? matchedCategories,
    String? selectedCategoryCode,
    String? selectedCategoryName,
    List<CostParameter>? costParameters,
    Map<String, dynamic>? costParameterValues,
    Map<String, String>? manualOverrides,
    CostEstimateResult? costEstimate,
    FactoryQuoteResult? factoryQuote,
    int? selectedSupplierIndex,
    bool clearSelectedSupplier = false,
    String? selectedSupplierCode,
    bool clearSupplierCode = false,
    List<CostParameter>? fobParameters,
    Map<String, dynamic>? fobParameterValues,
    FobEstimateResult? fobEstimate,
    Map<int, String>? rawResponses,
  }) {
    return SmartMatchState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      maxCompletedStep: maxCompletedStep ?? this.maxCompletedStep,
      aiThinkingText: clearAiThinking
          ? null
          : (aiThinkingText ?? this.aiThinkingText),
      productName: productName ?? this.productName,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      sessionId: sessionId ?? this.sessionId,
      matchedCategories: matchedCategories ?? this.matchedCategories,
      selectedCategoryCode: selectedCategoryCode ?? this.selectedCategoryCode,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      costParameters: costParameters ?? this.costParameters,
      costParameterValues: costParameterValues ?? this.costParameterValues,
      manualOverrides: manualOverrides ?? this.manualOverrides,
      costEstimate: costEstimate ?? this.costEstimate,
      factoryQuote: factoryQuote ?? this.factoryQuote,
      selectedSupplierIndex: clearSelectedSupplier
          ? null
          : (selectedSupplierIndex ?? this.selectedSupplierIndex),
      selectedSupplierCode: clearSupplierCode
          ? null
          : (selectedSupplierCode ?? this.selectedSupplierCode),
      fobParameters: fobParameters ?? this.fobParameters,
      fobParameterValues: fobParameterValues ?? this.fobParameterValues,
      fobEstimate: fobEstimate ?? this.fobEstimate,
      rawResponses: rawResponses ?? this.rawResponses,
    );
  }

  /// Whether the current step can proceed
  bool get canProceed {
    switch (currentStep) {
      case 0:
        return productName.trim().isNotEmpty && selectedCategoryCode != null;
      case 1:
        // Check all required parameters are filled
        for (final param in costParameters) {
          if (param.required) {
            final value = costParameterValues[param.parameterCode];
            if (value == null || value.toString().trim().isEmpty) return false;
          }
        }
        return costParameters.isNotEmpty;
      case 2:
        return costEstimate != null;
      case 3:
        return factoryQuote != null;
      case 4:
        return fobEstimate != null;
      default:
        return false;
    }
  }
}

/// Format raw JSON Map to readable string
String _formatRaw(Map<String, dynamic> raw) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(raw);
}

/// Save raw response to rawResponses map
Map<int, String> _mergeRaw(
  Map<int, String> existing,
  int step,
  Map<String, dynamic> raw,
) {
  return {...existing, step: _formatRaw(raw)};
}

/// Smart match Notifier - manages 5-step flow
class SmartMatchNotifier extends StateNotifier<SmartMatchState> {
  final SmartMatchRepository _repo;

  SmartMatchNotifier(this._repo) : super(const SmartMatchState());

  // ========== Step 1: Product matching ==========

  void updateProductName(String name) {
    state = state.copyWith(productName: name, clearError: true);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setImageUrl(String? url) {
    if (url != null) {
      state = state.copyWith(imageUrl: url);
    } else {
      state = state.copyWith(clearImageUrl: true);
    }
  }

  /// AI category matching - call backend API
  Future<void> matchProduct() async {
    if (state.productName.trim().isEmpty) {
      state = state.copyWith(error: 'smart_match.enter_product_name'.tr());
      return;
    }
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      aiThinkingText: 'smart_match.ai_analyzing'.tr(),
    );
    try {
      final result = await _repo.matchCategories(
        state.productName,
        imageUrl: state.imageUrl,
      );
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        sessionId: result.parsed.sessionId,
        matchedCategories: result.parsed.categories,
        rawResponses: _mergeRaw(state.rawResponses, 0, result.raw),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        error: _formatError('smart_match.category_match_failed'.tr(), e),
      );
    }
  }

  /// Select category
  void selectCategory(String categoryCode, String categoryName) {
    state = state.copyWith(
      selectedCategoryCode: categoryCode,
      selectedCategoryName: categoryName,
    );
  }

  // ========== Step 2: Cost parameters ==========

  /// Enter Step 2 and load dynamic parameters
  Future<void> proceedToStep2() async {
    if (state.selectedCategoryCode == null || state.sessionId == null) return;

    state = state.copyWith(
      currentStep: 1,
      maxCompletedStep: 0,
      isLoading: true,
      clearError: true,
      aiThinkingText: 'smart_match.ai_generating_params'.tr(),
    );
    try {
      final result = await _repo.getCostParameters(
        state.sessionId!,
        state.selectedCategoryCode!,
      );
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        costParameters: result.parsed,
        costParameterValues: {},
        manualOverrides: {},
        rawResponses: _mergeRaw(state.rawResponses, 1, result.raw),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        error: _formatError('smart_match.load_params_failed'.tr(), e),
      );
    }
  }

  /// Update parameter value
  void updateCostParam(String paramCode, dynamic value) {
    final newValues = Map<String, dynamic>.from(state.costParameterValues);
    newValues[paramCode] = value;
    state = state.copyWith(costParameterValues: newValues);
  }

  /// Set manual override value
  void setManualOverride(String paramCode, String value) {
    final newOverrides = Map<String, String>.from(state.manualOverrides);
    if (value.isEmpty) {
      newOverrides.remove(paramCode);
    } else {
      newOverrides[paramCode] = value;
    }
    state = state.copyWith(manualOverrides: newOverrides);
  }

  /// Remove manual override
  void removeManualOverride(String paramCode) {
    final newOverrides = Map<String, String>.from(state.manualOverrides);
    newOverrides.remove(paramCode);
    state = state.copyWith(manualOverrides: newOverrides);
  }

  // ========== Step 3: Cost estimate ==========

  /// Submit parameters and get cost estimate
  Future<void> submitCostParams() async {
    state = state.copyWith(
      currentStep: 2,
      maxCompletedStep: 1,
      isLoading: true,
      clearError: true,
      aiThinkingText: 'smart_match.ai_estimating_cost'.tr(),
    );
    try {
      // Merge parameter values: manual override takes priority
      final mergedParams = Map<String, dynamic>.from(state.costParameterValues);
      for (final entry in state.manualOverrides.entries) {
        if (entry.value.isNotEmpty) {
          mergedParams[entry.key] = entry.value;
        }
      }

      final result = await _repo.estimateCost(
        state.sessionId!,
        mergedParams,
        categoryCode: state.selectedCategoryCode,
        imageUrl: state.imageUrl,
      );
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        costEstimate: result.parsed,
        rawResponses: _mergeRaw(state.rawResponses, 2, result.raw),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        error: _formatError('smart_match.cost_estimate_failed'.tr(), e),
      );
    }
  }

  // ========== Step 4: Factory quotes ==========

  /// Get factory quotes
  Future<void> loadFactoryQuote() async {
    state = state.copyWith(
      currentStep: 3,
      maxCompletedStep: 2,
      isLoading: true,
      clearError: true,
      aiThinkingText: 'smart_match.getting_factory_quotes'.tr(),
    );
    try {
      final result = await _repo.getFactoryQuote(
        state.sessionId!,
        state.selectedCategoryCode!,
      );
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        factoryQuote: result.parsed,
        rawResponses: _mergeRaw(state.rawResponses, 3, result.raw),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        error: _formatError('smart_match.get_quotes_failed'.tr(), e),
      );
    }
  }

  void selectSupplier(int index) {
    // Also save supplierCode if available
    String? code;
    final quote = state.factoryQuote;
    if (quote != null && index < quote.supplierQuotes.length) {
      code = quote.supplierQuotes[index].supplierCode;
    }
    state = state.copyWith(
      selectedSupplierIndex: index,
      selectedSupplierCode: code,
    );
  }

  /// Select supplier by supplierCode
  void selectSupplierByCode(String code) {
    state = state.copyWith(selectedSupplierCode: code);
  }

  // ========== Step 5: FOB estimate ==========

  /// Load FOB parameters and enter Step 5
  Future<void> loadFobParams() async {
    // If no supplier selected, auto-use the first one
    String? supplierCode = state.selectedSupplierCode;
    if (supplierCode == null || supplierCode.isEmpty) {
      final quote = state.factoryQuote;
      if (quote != null && quote.supplierQuotes.isNotEmpty) {
        supplierCode = quote.supplierQuotes.first.supplierCode;
      }
    }

    state = state.copyWith(
      currentStep: 4,
      maxCompletedStep: 3,
      isLoading: true,
      clearError: true,
      aiThinkingText: 'smart_match.loading_fob_params'.tr(),
      selectedSupplierCode: supplierCode,
    );
    try {
      final result = await _repo.getFobParameters(
        state.sessionId!,
        state.selectedCategoryCode!,
      );
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        fobParameters: result.parsed,
        fobParameterValues: {},
        rawResponses: _mergeRaw(state.rawResponses, 4, result.raw),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        error: _formatError('smart_match.load_fob_failed'.tr(), e),
      );
    }
  }

  void updateFobParam(String paramCode, dynamic value) {
    final newValues = Map<String, dynamic>.from(state.fobParameterValues);
    newValues[paramCode] = value;
    state = state.copyWith(fobParameterValues: newValues);
  }

  /// Submit FOB parameters and get estimate
  Future<void> submitFobParams() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      aiThinkingText: 'smart_match.calculating_fob'.tr(),
    );
    try {
      final result = await _repo.estimateFob(
        state.sessionId!,
        state.fobParameterValues,
        supplierCode: state.selectedSupplierCode,
      );
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        maxCompletedStep: 4,
        fobEstimate: result.parsed,
        rawResponses: _mergeRaw(state.rawResponses, 5, result.raw),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAiThinking: true,
        error: _formatError('smart_match.fob_calc_failed'.tr(), e),
      );
    }
  }

  // ========== Step navigation ==========

  /// Go to specified step (only allow going back to completed steps)
  void goToStep(int step) {
    if (step >= 0 && step <= state.maxCompletedStep) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  /// Reset all state
  void reset() {
    state = const SmartMatchState();
  }

  /// Format error message
  String _formatError(String prefix, dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      // DioException usually contains message
      if (msg.contains('message:')) {
        final parts = msg.split('message:');
        if (parts.length > 1) {
          return '$prefix: ${parts.last.trim()}';
        }
      }
      if (msg.contains('SocketException') || msg.contains('Connection')) {
        return '$prefix: ${'common.network_error'.tr()}';
      }
      if (msg.contains('timeout') || msg.contains('Timeout')) {
        return '$prefix: ${'smart_match.request_timeout'.tr()}';
      }
    }
    return '$prefix: $e';
  }
}

/// SmartMatch StateNotifier Provider
final smartMatchProvider =
    StateNotifierProvider<SmartMatchNotifier, SmartMatchState>((ref) {
      final repo = ref.read(smartMatchRepositoryProvider);
      return SmartMatchNotifier(repo);
    });
