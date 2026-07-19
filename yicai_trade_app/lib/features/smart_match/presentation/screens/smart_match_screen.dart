import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../data/models/smart_match_models.dart';
import '../providers/smart_match_provider.dart';

/// AI 智能匹配 5 步向导 - 与网站 smart-match.html 完全对齐
/// 产品匹配 → 成本参数 → 成本预估 → 工厂报价 → FOB预估
class SmartMatchScreen extends ConsumerStatefulWidget {
  const SmartMatchScreen({super.key});

  @override
  ConsumerState<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends ConsumerState<SmartMatchScreen> {
  final _productNameCtrl = TextEditingController();
  final _scrollController = ScrollController();

  /// 管理动态参数字段的 TextEditingController，避免每次 rebuild 重建
  final Map<String, TextEditingController> _paramControllers = {};

  /// 手动输入覆盖的控制器
  final Map<String, TextEditingController> _manualControllers = {};

  /// 当前显示手动输入的参数代码集合
  final Set<String> _showManualInput = {};

  static List<String> get _steps => [
    'smart_match.step_product'.tr(),
    'smart_match.step_params'.tr(),
    'smart_match.step_cost'.tr(),
    'smart_match.step_quote'.tr(),
    'smart_match.step_fob'.tr(),
  ];

  /// AI 思考过程打字机文本
  String _typedText = '';
  Timer? _typeTimer;
  int _thinkingPhase = 0;
  Timer? _phaseTimer;
  double _progressValue = 0;
  Timer? _progressTimer;

  /// 佣金模块状态（与网站 commissionSettings 一致）
  double _rebateRate = 0.03; // 默认3%返佣

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _scrollController.dispose();
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    for (final c in _manualControllers.values) {
      c.dispose();
    }
    _typeTimer?.cancel();
    _phaseTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  /// 获取或创建参数对应的 TextEditingController
  TextEditingController _getParamController(String code, String? initialText) {
    final ctrl = _paramControllers.putIfAbsent(code, () {
      return TextEditingController(text: initialText ?? '');
    });
    if (ctrl.text != (initialText ?? '') && initialText != null) {
      ctrl.text = initialText;
      ctrl.selection = TextSelection.collapsed(offset: initialText.length);
    }
    return ctrl;
  }

  /// 获取手动输入控制器
  TextEditingController _getManualController(String code, String? initial) {
    return _manualControllers.putIfAbsent(code, () {
      return TextEditingController(text: initial ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartMatchProvider);

    // 当步骤变化时清空参数控制器缓存
    ref.listen(smartMatchProvider.select((s) => s.currentStep), (prev, next) {
      if (prev != next) {
        _clearParamControllers();
        _showManualInput.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    // 当 loading 变化时启动/停止 AI 思考动画
    ref.listen(smartMatchProvider.select((s) => s.isLoading), (prev, next) {
      if (next) {
        _startAiThinkingAnimation(ref.read(smartMatchProvider).currentStep);
      } else {
        _stopAiThinkingAnimation();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text('smart_match.title'.tr()),
        backgroundColor: AppColors.pageBg,
        scrolledUnderElevation: 0,
        actions: [
          if (state.currentStep > 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _clearParamControllers();
                _productNameCtrl.clear();
                ref.read(smartMatchProvider.notifier).reset();
              },
              tooltip: 'common.reset'.tr(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(state),
          if (state.error != null) _buildErrorBanner(state.error!),
          Expanded(
            child: state.isLoading
                ? _buildAiThinkingPanel(state)
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(state.currentStep),
                        child: _buildStepContent(state),
                      ),
                    ),
                  ),
          ),
          _buildBottomActions(state),
        ],
      ),
    );
  }

  void _clearParamControllers() {
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    _paramControllers.clear();
    for (final c in _manualControllers.values) {
      c.dispose();
    }
    _manualControllers.clear();
  }

  // ======================== AI 思考动画 ========================

  static List<List<String>> get _thinkingPhases => <List<String>>[
    // Step 0: 品类匹配
    [
      'smart_match.thinking_0_0'.tr(),
      'smart_match.thinking_0_1'.tr(),
      'smart_match.thinking_0_2'.tr(),
      'smart_match.thinking_0_3'.tr(),
    ],
    // Step 1: 成本参数
    [
      'smart_match.thinking_1_0'.tr(),
      'smart_match.thinking_1_1'.tr(),
      'smart_match.thinking_1_2'.tr(),
    ],
    // Step 2: 成本预估
    [
      'smart_match.thinking_2_0'.tr(),
      'smart_match.thinking_2_1'.tr(),
      'smart_match.thinking_2_2'.tr(),
      'smart_match.thinking_2_3'.tr(),
      'smart_match.thinking_2_4'.tr(),
      'smart_match.thinking_2_5'.tr(),
      'smart_match.thinking_2_6'.tr(),
    ],
    // Step 3: 工厂报价
    [
      'smart_match.thinking_3_0'.tr(),
      'smart_match.thinking_3_1'.tr(),
      'smart_match.thinking_3_2'.tr(),
      'smart_match.thinking_3_3'.tr(),
    ],
    // Step 4: FOB 预估
    [
      'smart_match.thinking_4_0'.tr(),
      'smart_match.thinking_4_1'.tr(),
      'smart_match.thinking_4_2'.tr(),
      'smart_match.thinking_4_3'.tr(),
    ],
  ];

  void _startAiThinkingAnimation(int step) {
    _stopAiThinkingAnimation();
    _thinkingPhase = 0;
    _progressValue = 0;
    _typedText = '';

    final phases = step < _thinkingPhases.length
        ? _thinkingPhases[step]
        : _thinkingPhases[0];

    _startTypeWriter(phases[0]);

    // 每3秒切换下一个阶段
    _phaseTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _thinkingPhase++;
      if (_thinkingPhase < phases.length) {
        _startTypeWriter(phases[_thinkingPhase]);
      } else {
        // 循环最后一个
        _startTypeWriter(phases.last);
      }
    });

    // 进度条动画
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted) {
        setState(() {
          if (_progressValue < 0.6) {
            _progressValue += 0.02;
          } else if (_progressValue < 0.9) {
            _progressValue += 0.005;
          } else if (_progressValue < 0.95) {
            _progressValue += 0.001;
          }
        });
      }
    });
  }

  void _startTypeWriter(String text) {
    _typeTimer?.cancel();
    int charIndex = 0;
    if (mounted) {
      setState(() => _typedText = '');
    }
    _typeTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (charIndex < text.length && mounted) {
        setState(() {
          _typedText = text.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  void _stopAiThinkingAnimation() {
    _typeTimer?.cancel();
    _phaseTimer?.cancel();
    _progressTimer?.cancel();
  }

  Widget _buildAiThinkingPanel(SmartMatchState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            // AI 思考框
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'smart_match.ai_thinking'.tr(),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: _typedText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(
                          text: '|',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progressValue * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== 步骤指示器 ========================

  Widget _buildStepIndicator(SmartMatchState state) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i == state.currentStep;
          final isCompleted = i <= state.maxCompletedStep;
          final canTap = isCompleted && i != state.currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: canTap
                  ? () => ref.read(smartMatchProvider.notifier).goToStep(i)
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 2,
                            color: isCompleted || isActive
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.primary
                              : isCompleted
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.cardBg,
                          border: Border.all(
                            color: isActive || isCompleted
                                ? AppColors.primary
                                : AppColors.divider,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isCompleted && !isActive
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primary,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.black
                                      : AppColors.textSecondary,
                                ),
                              ),
                      ),
                      if (i < _steps.length - 1)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 2,
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            onPressed: () => ref.read(smartMatchProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ======================== 步骤内容切换 ========================

  Widget _buildStepContent(SmartMatchState state) {
    switch (state.currentStep) {
      case 0:
        return _buildStep1Product(state);
      case 1:
        return _buildStep2Params(state);
      case 2:
        return _buildStep3Cost(state);
      case 3:
        return _buildStep4Quote(state);
      case 4:
        return _buildStep5Fob(state);
      default:
        return const SizedBox.shrink();
    }
  }

  // ======================== Step 1: 产品匹配 ========================

  Widget _buildStep1Product(SmartMatchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 识别横幅
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'smart_match.ai_product_id'.tr(),
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'smart_match.ai_product_desc'.tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 产品名称输入
        _buildSectionTitle('smart_match.product_name'.tr()),
        const SizedBox(height: 8),
        TextField(
          controller: _productNameCtrl,
          onChanged: (v) =>
              ref.read(smartMatchProvider.notifier).updateProductName(v),
          style: const TextStyle(color: AppColors.textTitle),
          decoration: _inputDecoration('smart_match.product_name_hint'.tr()),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (state.productName.trim().isNotEmpty &&
                state.matchedCategories.isEmpty) {
              ref.read(smartMatchProvider.notifier).matchProduct();
            }
          },
        ),
        const SizedBox(height: 16),

        // 图片上传区
        _buildSectionTitle('smart_match.product_image'.tr()),
        const SizedBox(height: 8),
        _buildImageUploadArea(state),
        const SizedBox(height: 24),

        // 开始匹配按钮
        if (state.matchedCategories.isEmpty)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.productName.trim().isNotEmpty
                  ? () => ref.read(smartMatchProvider.notifier).matchProduct()
                  : null,
              icon: const Icon(Icons.search),
              label: Text('smart_match.start_match'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

        // 品类匹配结果
        if (state.matchedCategories.isNotEmpty) ...[
          _buildSectionTitle('smart_match.match_categories'.tr()),
          const SizedBox(height: 12),
          ...state.matchedCategories.map(
            (cat) => _buildCategoryCard(cat, state),
          ),
        ],
      ],
    );
  }

  Widget _buildImageUploadArea(SmartMatchState state) {
    return GestureDetector(
      onTap: state.imageUrl == null ? _showImagePicker : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: state.imageUrl != null
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            width: state.imageUrl != null ? 2 : 1,
          ),
        ),
        child: state.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      state.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textPlaceholder,
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'smart_match.image_load_fail'.tr(),
                              style: TextStyle(
                                color: AppColors.textPlaceholder,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(smartMatchProvider.notifier)
                            .setImageUrl(null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.textPlaceholder,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'smart_match.upload_image'.tr(),
                    style: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'smart_match.upload_support'.tr(),
                    style: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryCard(MatchedCategory cat, SmartMatchState state) {
    final isSelected = state.selectedCategoryCode == cat.categoryCode;
    return GestureDetector(
      onTap: () => ref
          .read(smartMatchProvider.notifier)
          .selectCategory(cat.categoryCode, cat.categoryName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.categoryName,
                    style: const TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${'smart_match.match_score'.tr()} ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: cat.matchScore,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cat.matchScore > 0.8
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(cat.matchScore * 100).toInt()}%',
                        style: TextStyle(
                          color: cat.matchScore > 0.8
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== Step 2: 成本参数 ========================

  Widget _buildStep2Params(SmartMatchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'smart_match.category_info'.tr(
                    args: [
                      state.selectedCategoryName ?? '',
                      '${state.costParameters.length}',
                    ],
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...state.costParameters.map((param) => _buildParamField(param, state)),
        // 提示区域（与网站一致）
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'smart_match.tip'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'smart_match.tip_manual_input'.tr(),
                      style: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParamField(CostParameter param, SmartMatchState state) {
    final value = state.costParameterValues[param.parameterCode];
    final hasManualOverride = _showManualInput.contains(param.parameterCode);
    final manualValue = state.manualOverrides[param.parameterCode];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 参数名称（与网站一致：label 单独一行）
          Row(
            children: [
              Text(
                param.parameterName,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (param.required)
                const Text(
                  ' *',
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 2. 字段（与网站一致：字段在 label 下方）
          if (hasManualOverride) ...[
            // 手动输入模式 - 替代原来的下拉框
            TextField(
              controller: _getManualController(
                param.parameterCode,
                manualValue,
              ),
              style: const TextStyle(color: AppColors.textTitle),
              decoration: _inputDecoration(
                'smart_match.manual_input_hint'.tr(args: [param.parameterName]),
                suffix: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              onChanged: (v) => ref
                  .read(smartMatchProvider.notifier)
                  .setManualOverride(param.parameterCode, v),
            ),
          ] else if (param.parameterType == 'select') ...[
            _buildSelectField(param, value),
          ] else if (param.parameterType == 'number') ...[
            _buildNumberField(param, value),
          ] else ...[
            _buildTextField(param, value),
          ],
          // 3. 描述文字（与网站一致：在字段下方）
          if (param.description != null) ...[
            const SizedBox(height: 6),
            Text(
              param.description!,
              style: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 12,
              ),
            ),
          ],
          // 4. 手动输入切换链接（与网站一致：在描述下方，独立一行）
          if (param.parameterType == 'select') ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (hasManualOverride) {
                    _showManualInput.remove(param.parameterCode);
                    ref
                        .read(smartMatchProvider.notifier)
                        .removeManualOverride(param.parameterCode);
                  } else {
                    _showManualInput.add(param.parameterCode);
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasManualOverride
                        ? 'smart_match.close_manual'.tr()
                        : 'smart_match.manual_input'.tr(),
                    style: TextStyle(
                      color: hasManualOverride
                          ? AppColors.error
                          : AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectField(CostParameter param, dynamic value) {
    final allOptions = [...param.options];
    if (param.allowAIEstimate && param.aiEstimateOption != null) {
      allOptions.add(param.aiEstimateOption!);
    }
    // 确保 value 在选项列表中，否则设为 null
    final currentValue =
        (value != null && allOptions.contains(value.toString()))
        ? value.toString()
        : null;
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: _inputDecoration(
        'smart_match.select_hint'.tr(args: [param.parameterName]),
      ),
      dropdownColor: AppColors.cardBg,
      style: const TextStyle(color: AppColors.textTitle, fontSize: 14),
      items: allOptions
          .map(
            (opt) => DropdownMenuItem(
              value: opt,
              child: Text(
                opt,
                style: TextStyle(
                  color: opt == param.aiEstimateOption
                      ? AppColors.primary
                      : AppColors.textTitle,
                  fontStyle: opt == param.aiEstimateOption
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => ref
          .read(smartMatchProvider.notifier)
          .updateCostParam(param.parameterCode, v),
    );
  }

  Widget _buildNumberField(CostParameter param, dynamic value) {
    final ctrl = _getParamController(
      'cost_${param.parameterCode}',
      value?.toString(),
    );
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textTitle),
      decoration: _inputDecoration(
        'smart_match.input_hint'.tr(args: [param.parameterName]),
        suffix: param.unit != null
            ? Text(
                param.unit!,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
      ),
      onChanged: (v) => ref
          .read(smartMatchProvider.notifier)
          .updateCostParam(param.parameterCode, v),
    );
  }

  Widget _buildTextField(CostParameter param, dynamic value) {
    final ctrl = _getParamController(
      'cost_${param.parameterCode}',
      value?.toString(),
    );
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textTitle),
      decoration: _inputDecoration(
        'smart_match.input_hint'.tr(args: [param.parameterName]),
      ),
      onChanged: (v) => ref
          .read(smartMatchProvider.notifier)
          .updateCostParam(param.parameterCode, v),
    );
  }

  // ======================== Step 3: 成本预估 ========================

  Widget _buildStep3Cost(SmartMatchState state) {
    final cost = state.costEstimate;
    if (cost == null) {
      return Center(
        child: Text('common.no_data'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('smart_match.cost_detail'.tr()),
        if (cost.costSource != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              cost.costSource!,
              style: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 11,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _buildCostTable(cost),
        const SizedBox(height: 8),
        _buildCostSummary(cost),

        // 同平台市场参考价（与网站一致的阿里巴巴参考）
        if (cost.hasMarketReference) ...[
          const SizedBox(height: 16),
          _buildMarketReferenceCard(cost),
        ],

        const SizedBox(height: 24),
        if (cost.suppliers.isNotEmpty) ...[
          _buildSectionTitle('smart_match.recommended_suppliers'.tr()),
          const SizedBox(height: 12),
          ...cost.suppliers.map((s) => _buildSupplierCard(s)),
        ],
      ],
    );
  }

  /// 同平台市场参考价卡片（与网站黄色提示卡片一致）
  Widget _buildMarketReferenceCard(CostEstimateResult cost) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFD93D).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFFFF9800), size: 18),
              const SizedBox(width: 6),
              Text(
                'smart_match.market_reference'.tr(),
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (cost.alibabaReferenceNote != null &&
              cost.alibabaReferenceNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              // 与网站一致：将"阿里巴巴"替换为"同平台"
              cost.alibabaReferenceNote!.replaceAll('阿里巴巴', 'smart_match.platform_ref'.tr()),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          if (cost.platformPriceLow != null && cost.platformPriceLow! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'smart_match.market_ref_price'.tr(
                args: [
                  cost.platformPriceLow!.toStringAsFixed(2),
                  (cost.platformPriceHigh ?? cost.platformPriceLow!)
                      .toStringAsFixed(2),
                ],
              ),
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostTable(CostEstimateResult cost) {
    final items = cost.costBreakdownItems;
    if (items.isEmpty) {
      // 兼容：如果新字段为空，使用旧方式
      return _buildLegacyCostTable(cost);
    }
    return _buildGenericTable(
      'smart_match.cost_item'.tr(),
      'smart_match.amount_cny'.tr(),
      items,
    );
  }

  /// 兼容旧数据格式的成本表
  Widget _buildLegacyCostTable(CostEstimateResult cost) {
    final items = <(String, double)>[
      ('smart_match.material_cost'.tr(), cost.materialCost),
      if (cost.laborCost != null && cost.laborCost! > 0)
        ('smart_match.labor_cost'.tr(), cost.laborCost!),
      ('smart_match.packaging_cost'.tr(), cost.packagingCost),
      if (cost.shippingCost != null && cost.shippingCost! > 0)
        ('smart_match.shipping_cost'.tr(), cost.shippingCost!),
      if (cost.profit != null && cost.profit! > 0)
        ('smart_match.profit'.tr(), cost.profit!),
    ];
    return _buildGenericTable(
      'smart_match.cost_item'.tr(),
      'smart_match.amount_cny'.tr(),
      items,
    );
  }

  Widget _buildGenericTable(
    String col1Header,
    String col2Header,
    List<(String, double)> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    col1Header,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  col2Header,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '¥${item.$2.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(CostEstimateResult cost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'smart_match.estimated_price'.tr(),
            style: TextStyle(color: AppColors.textTitle, fontSize: 14),
          ),
          Text(
            cost.displayPriceRange,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(RecommendedSupplier s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // 匹配度圆形指示器（与网站一致）
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: s.matchScore / 100.0,
                  strokeWidth: 4,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    s.matchScore > 80 ? AppColors.success : AppColors.warning,
                  ),
                ),
                Text(
                  '${s.matchScore}',
                  style: const TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (s.certified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'smart_match.certified'.tr(),
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 城市 + 产业带
                if (s.city != null || s.industrialBelt != null)
                  Text(
                    [
                      s.city,
                      s.industrialBelt,
                    ].where((e) => e != null).join(' · '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (s.matchReason != null && s.matchReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      s.matchReason!,
                      style: const TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (s.estimatedCostPrice != null && s.estimatedCostPrice! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'smart_match.est_cost_price'.tr(
                        args: [s.estimatedCostPrice!.toStringAsFixed(2)],
                      ),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // 兼容旧字段
                if (s.unitPrice > 0)
                  Text(
                    '¥${s.unitPrice.toStringAsFixed(2)}/${'common.unit_piece'.tr()} | ${'smart_match.delivery_days'.tr(args: ['${s.deliveryDays}'])}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== Step 4: 工厂报价 ========================

  /// 匹配分数→颜色（与网站 scoreColor 一致）
  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF00E5CC);
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFFFD93D);
    return const Color(0xFFFF6B6B);
  }

  /// 匹配分数→标签（与网站 scoreLabel 一致）
  String _scoreLabel(int score) {
    if (score >= 90) return 'smart_match.excellent_match'.tr();
    if (score >= 75) return 'smart_match.good_match'.tr();
    if (score >= 60) return 'smart_match.fair_match'.tr();
    return 'smart_match.normal_match'.tr();
  }

  Widget _buildStep4Quote(SmartMatchState state) {
    final quote = state.factoryQuote;
    if (quote == null) {
      return Center(
        child: Text('common.no_data'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    // 供应商按匹配度排序（与网站一致）
    final suppliers = List<SupplierQuote>.from(quote.supplierQuotes)
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    final cur = quote.currency ?? 'CNY';
    final unt = quote.unit ?? 'common.unit_piece'.tr();

    // 计算预估合同金额（与网站一致：平均报价 × 数量）
    double estAmount = 0;
    if (suppliers.isNotEmpty) {
      final avgPrice =
          suppliers.fold<double>(
            0,
            (sum, s) => sum + (s.quoteLow + s.quoteHigh) / 2,
          ) /
          suppliers.length;
      estAmount = avgPrice * 1000; // 默认1000件
    }
    if (estAmount <= 0) {
      estAmount = quote.quoteHigh * 1000;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 1. AI智能供应商匹配头部（与网站完全一致） =====
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5CC), Color(0xFF00D9CC)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('🎯', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'smart_match.ai_supplier_match'.tr(),
                          style: TextStyle(
                            color: AppColors.textTitle,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'smart_match.ai_supplier_desc'.tr(),
                          style: TextStyle(
                            color: AppColors.textPlaceholder,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 匹配维度标签
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildDimensionTag(
                    'smart_match.dim_industrial'.tr(),
                    const Color(0xFF00E5CC),
                  ),
                  _buildDimensionTag(
                    'smart_match.dim_product_fit'.tr(),
                    const Color(0xFF10B981),
                  ),
                  _buildDimensionTag(
                    'smart_match.dim_cost_competitive'.tr(),
                    const Color(0xFFFFD93D),
                  ),
                  _buildDimensionTag(
                    'smart_match.dim_overall'.tr(),
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ===== 2. 报价总览 3栏（与网站完全一致） =====
        Row(
          children: [
            // 左：出厂成本基准
            Expanded(
              child: _buildOverviewCard(
                'smart_match.cost_base'.tr(),
                quote.costPrice != null && quote.costPrice! > 0
                    ? quote.costPrice!.toStringAsFixed(2)
                    : '-',
                '$cur/$unt',
                bgColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AppColors.textTitle,
              ),
            ),
            const SizedBox(width: 8),
            // 中：同平台参考价 or 行业利润率
            Expanded(
              child:
                  (quote.platformPriceLow != null &&
                      quote.platformPriceLow! > 0)
                  ? _buildOverviewCard(
                      'smart_match.platform_ref_price'.tr(),
                      '${quote.platformPriceLow!.toStringAsFixed(2)} ~ ${(quote.platformPriceHigh ?? quote.platformPriceLow!).toStringAsFixed(2)}',
                      '$cur/$unt',
                      bgColor: const Color(0xFFFFD93D).withValues(alpha: 0.08),
                      borderColor: const Color(
                        0xFFFFD93D,
                      ).withValues(alpha: 0.2),
                      valueColor: const Color(0xFFFFD93D),
                      labelColor: const Color(0xFFFFD93D),
                    )
                  : _buildOverviewCard(
                      'smart_match.industry_profit'.tr(),
                      '${(quote.industryProfitMarginLow ?? quote.profitMarginLow).toStringAsFixed(1)}% ~ ${(quote.industryProfitMarginHigh ?? quote.profitMarginHigh).toStringAsFixed(1)}%',
                      'smart_match.industry_ref'.tr(),
                      bgColor: const Color(0xFFFFD93D).withValues(alpha: 0.08),
                      borderColor: const Color(
                        0xFFFFD93D,
                      ).withValues(alpha: 0.15),
                      valueColor: const Color(0xFFFFD93D),
                      labelColor: const Color(0xFFFFD93D),
                    ),
            ),
            const SizedBox(width: 8),
            // 右：工厂预估报价
            Expanded(
              child: _buildOverviewCard(
                'smart_match.factory_quote'.tr(),
                '${quote.quoteLow.toStringAsFixed(2)} ~ ${quote.quoteHigh.toStringAsFixed(2)}',
                '$cur/$unt',
                bgColor: AppColors.primary.withValues(alpha: 0.08),
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                valueColor: AppColors.primary,
                labelColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ===== 3. 行业参考 + 报价规则（与网站完全一致） =====
        if (quote.industryReferenceNote != null &&
            quote.industryReferenceNote!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                      children: [
                        TextSpan(text: quote.industryReferenceNote!),
                        // 报价规则: 工厂报价不低于同平台参考最低价（关键算法）
                        if (quote.platformPriceLow != null &&
                            quote.platformPriceLow! > 0) ...[
                          const TextSpan(text: '\n'),
                          TextSpan(
                            text: 'smart_match.quote_rule'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'smart_match.quote_rule_desc'.tr(
                              args: [
                                quote.platformPriceLow!.toStringAsFixed(2),
                                '$cur/$unt',
                              ],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD93D),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ===== 4. 免责声明（与网站完全一致） =====
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'smart_match.price_disclaimer'.tr(),
            style: TextStyle(
              color: AppColors.textPlaceholder,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ===== 5. 供应商匹配列表（与网站完全一致） =====
        if (suppliers.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'smart_match.supplier_recommend'.tr(),
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'smart_match.supplier_count_sort'.tr(
                  args: ['${suppliers.length}'],
                ),
                style: const TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suppliers.asMap().entries.map((entry) {
            final i = entry.key;
            final sq = entry.value;
            final isTop = i == 0;
            final score = sq.matchScore > 0 ? sq.matchScore : 75;
            final color = _scoreColor(score);
            final label = _scoreLabel(score);
            final isSelected =
                state.selectedSupplierCode == sq.supplierCode ||
                state.selectedSupplierIndex == i;
            final costPrice =
                sq.estimatedCostPrice != null && sq.estimatedCostPrice! > 0
                ? sq.estimatedCostPrice!
                : (quote.costPrice ?? 0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isTop
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.06),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                      )
                    : null,
                color: isTop ? null : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isTop
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 最佳匹配标签
                  if (isTop)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5CC), Color(0xFF00D9CC)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'smart_match.best_match'.tr(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 匹配分数环（与网站SVG圆环一致）
                      SizedBox(
                        width: 64,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: score / 100.0,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.06,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                  ),
                                  Text(
                                    '$score',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 供应商详情
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 名称 + 地理位置
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  sq.supplierName,
                                  style: const TextStyle(
                                    color: AppColors.textTitle,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (sq.city != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '📍 ${sq.city}',
                                      style: const TextStyle(
                                        color: AppColors.textPlaceholder,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // 匹配原因高亮框
                            if (sq.matchReason != null &&
                                sq.matchReason!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isTop
                                      ? AppColors.primary.withValues(
                                          alpha: 0.04,
                                        )
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border(
                                    left: BorderSide(color: color, width: 3),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'smart_match.match_reason'.tr(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: sq.matchReason!),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            // 匹配维度标签（产业带/主营/出厂价）
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                if (sq.industrialBelt != null)
                                  _buildSupplierTag(
                                    '🏭 ${sq.industrialBelt}',
                                    const Color(0xFF00E5CC),
                                  ),
                                if (sq.mainProducts != null)
                                  _buildSupplierTag(
                                    '📦 ${sq.mainProducts}',
                                    const Color(0xFF10B981),
                                  ),
                                _buildSupplierTag(
                                  '💰 ${'smart_match.factory_price'.tr()} ${costPrice.toStringAsFixed(2)} $cur',
                                  const Color(0xFF8B5CF6),
                                ),
                              ],
                            ),
                            // 报价区间 + 选此供应商按钮
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'smart_match.est_quote'.tr(),
                                        style: TextStyle(
                                          color: AppColors.textPlaceholder,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '${sq.quoteLow.toStringAsFixed(2)} ~ ${sq.quoteHigh.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '$cur/$unt',
                                        style: const TextStyle(
                                          color: AppColors.textPlaceholder,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 选此供应商按钮（与网站 selectSupplierForFOB 一致）
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(smartMatchProvider.notifier)
                                        .selectSupplier(i);
                                    if (sq.supplierCode != null) {
                                      ref
                                          .read(smartMatchProvider.notifier)
                                          .selectSupplierByCode(
                                            sq.supplierCode!,
                                          );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? AppColors.primary
                                        : isTop
                                        ? AppColors.primary
                                        : AppColors.cardBg,
                                    foregroundColor: isSelected || isTop
                                        ? Colors.black
                                        : AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: isSelected || isTop
                                          ? BorderSide.none
                                          : const BorderSide(
                                              color: AppColors.primary,
                                            ),
                                    ),
                                    elevation: isTop ? 4 : 0,
                                  ),
                                  child: Text(
                                    isSelected
                                        ? 'smart_match.selected'.tr()
                                        : 'smart_match.select_supplier'.tr(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],

        // ===== 6. 佣金模块（与网站 renderCommissionModule 一致） =====
        const SizedBox(height: 8),
        _buildCommissionModule(estAmount),

        // ===== 7. FOB预估提示（与网站完全一致） =====
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'smart_match.fob_question'.tr(),
                style: TextStyle(
                  color: Color(0xFFD4A00D),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'smart_match.fob_includes'.tr(),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleNextStep(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'smart_match.yes_fob'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('smart_match.match_complete'.tr()),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'smart_match.no_fob'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ===== 8. 平台代采合同入口（与网站完全一致） =====
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'smart_match.platform_contract'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'smart_match.platform_contract_desc'.tr(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showContractConfirm(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'smart_match.sign_contract'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 报价总览卡片
  Widget _buildOverviewCard(
    String title,
    String value,
    String subtitle, {
    Color? bgColor,
    Color? borderColor,
    Color? valueColor,
    Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: labelColor ?? AppColors.textPlaceholder,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textTitle,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textPlaceholder,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 匹配维度标签（产业带匹配/产品契合度等）
  Widget _buildDimensionTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  /// 供应商详情标签（产业带/主营产品/出厂价）
  Widget _buildSupplierTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  /// 佣金模块（与网站 renderCommissionModule 完全一致）
  Widget _buildCommissionModule(double contractAmount) {
    const platformFixedRate = 0.02;
    final platformFee = contractAmount * platformFixedRate;
    final rebateAmount = contractAmount * _rebateRate;
    final totalServiceFee = platformFee + rebateAmount;
    final pctVal = (_rebateRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD93D).withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'smart_match.service_fee_title'.tr(),
                      style: TextStyle(
                        color: Color(0xFFFFD93D),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'smart_match.service_fee_desc'.tr(),
                      style: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 费用结构：平台固定佣金 + 合同返佣
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD93D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'smart_match.platform_commission'.tr(),
                              style: TextStyle(
                                color: Color(0xFFFFD93D),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          platformFee.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'smart_match.commission_formula'.tr(args: ['2']),
                        style: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'smart_match.contract_rebate'.tr(),
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rebateAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'smart_match.commission_formula'.tr(args: ['$pctVal']),
                        style: const TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 返佣比例设置滑块
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'smart_match.set_rebate_rate'.tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$pctVal%',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      '1%',
                      style: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 10,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _rebateRate * 100,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.divider,
                        onChanged: (v) => setState(() => _rebateRate = v / 100),
                      ),
                    ),
                    const Text(
                      '10%',
                      style: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                // 快速选择按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(10, (i) {
                    final v = i + 1;
                    final isActive = v == pctVal;
                    return GestureDetector(
                      onTap: () => setState(() => _rebateRate = v / 100),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            '$v',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textPlaceholder,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 费用汇总
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'smart_match.platform_commission_pct'.tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '¥${platformFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'smart_match.rebate_amount_pct'.tr(args: ['$pctVal']),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '¥${rebateAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'smart_match.total_service_fee'.tr(),
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '¥${totalServiceFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 返佣说明
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'smart_match.rebate_return_note'.tr(
                            args: [rebateAmount.toStringAsFixed(2)],
                          ),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== Step 5: FOB 预估 ========================

  Widget _buildStep5Fob(SmartMatchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FOB 参数表单
        if (state.fobEstimate == null) ...[
          _buildSectionTitle('smart_match.fob_params'.tr()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'smart_match.fob_param_desc'.tr(),
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...state.fobParameters.map(
            (param) => _buildFobParamField(param, state),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(smartMatchProvider.notifier).submitFobParams(),
              icon: const Icon(Icons.calculate),
              label: Text('smart_match.calc_fob'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],

        // FOB 结果
        if (state.fobEstimate != null) ...[
          _buildSectionTitle('smart_match.fob_breakdown'.tr()),

          // 运输路线
          if (state.fobEstimate!.routeDescription != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'smart_match.route'.tr(
                        args: [state.fobEstimate!.routeDescription!],
                      ),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // FOB成本卡片网格（与网站 renderFOBResult 完全一致）
          _buildFobBreakdownCards(state.fobEstimate!),

          const SizedBox(height: 16),

          // 供应商FOB价格列表（与网站样式一致）
          if (state.fobEstimate!.supplierFOBPrices.isNotEmpty) ...[
            _buildSectionTitle('smart_match.supplier_fob_prices'.tr()),
            const SizedBox(height: 8),
            ...state.fobEstimate!.supplierFOBPrices.map(
              (sp) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sp.factoryName,
                            style: const TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (sp.city != null)
                            Text(
                              '📍 ${sp.city}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sp.fobPrice.toStringAsFixed(2)} ${state.fobEstimate!.currency ?? "CNY"}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'smart_match.domestic_freight_label'.tr(
                            args: [
                              sp.domesticFreight.toStringAsFixed(2),
                              sp.estimatedDeliveryDays > 0
                                  ? 'smart_match.delivery_days_unit'.tr(
                                      args: ['${sp.estimatedDeliveryDays}'],
                                    )
                                  : '-',
                            ],
                          ),
                          style: const TextStyle(
                            color: AppColors.textPlaceholder,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 佣金模块（与网站 renderCommissionModule 一致）
          () {
            final fob = state.fobEstimate!;
            double fobAmount = 0;
            if (fob.supplierFOBPrices.isNotEmpty) {
              final avgFob =
                  fob.supplierFOBPrices.fold<double>(
                    0,
                    (sum, s) => sum + s.fobPrice,
                  ) /
                  fob.supplierFOBPrices.length;
              fobAmount = avgFob * 1000;
            } else {
              fobAmount = fob.displayFobPrice * 1000;
            }
            return _buildCommissionModule(fobAmount);
          }(),
          // 操作按钮区（与网站完全一致）
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('smart_match.report_export_coming'.tr()),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: Text('smart_match.export_report'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showContractConfirm(state),
                  icon: const Text('🤝', style: TextStyle(fontSize: 14)),
                  label: Text('smart_match.platform_purchase'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// FOB 参数字段 - 与网站 renderFOBParams 对齐（含手动输入）
  Widget _buildFobParamField(CostParameter param, SmartMatchState state) {
    final value = state.fobParameterValues[param.parameterCode];
    // FOB 参数也支持手动输入覆盖，使用 'fob_' 前缀区分
    final manualKey = 'fob_${param.parameterCode}';
    final hasManualOverride = _showManualInput.contains(manualKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 参数名称
          Row(
            children: [
              Text(
                param.parameterName,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (param.required)
                const Text(
                  ' *',
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 2. 字段
          if (hasManualOverride) ...[
            TextField(
              controller: _getManualController(manualKey, null),
              style: const TextStyle(color: AppColors.textTitle),
              decoration: _inputDecoration(
                'smart_match.manual_input_hint'.tr(args: [param.parameterName]),
                suffix: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              onChanged: (v) => ref
                  .read(smartMatchProvider.notifier)
                  .updateFobParam(param.parameterCode, v),
            ),
          ] else if (param.parameterType == 'select') ...[
            DropdownButtonFormField<String>(
              initialValue:
                  (value != null && param.options.contains(value.toString()))
                  ? value.toString()
                  : null,
              decoration: _inputDecoration(
                'smart_match.select_hint'.tr(args: [param.parameterName]),
              ),
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(color: AppColors.textTitle, fontSize: 14),
              items: [
                ...param.options.map(
                  (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                ),
                if (param.allowAIEstimate && param.aiEstimateOption != null)
                  DropdownMenuItem(
                    value: param.aiEstimateOption,
                    child: Text(
                      param.aiEstimateOption!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => ref
                  .read(smartMatchProvider.notifier)
                  .updateFobParam(param.parameterCode, v),
            ),
          ] else ...[
            TextField(
              controller: _getParamController(
                'fob_${param.parameterCode}',
                value?.toString(),
              ),
              keyboardType: param.parameterType == 'number'
                  ? TextInputType.number
                  : TextInputType.text,
              style: const TextStyle(color: AppColors.textTitle),
              decoration: _inputDecoration(
                'smart_match.input_hint'.tr(args: [param.parameterName]),
                suffix: param.unit != null
                    ? Text(
                        param.unit!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      )
                    : null,
              ),
              onChanged: (v) => ref
                  .read(smartMatchProvider.notifier)
                  .updateFobParam(param.parameterCode, v),
            ),
          ],
          // 3. 描述文字
          if (param.description != null) ...[
            const SizedBox(height: 6),
            Text(
              param.description!,
              style: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 12,
              ),
            ),
          ],
          // 4. 手动输入切换（与网站一致）
          if (param.parameterType == 'select') ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (hasManualOverride) {
                    _showManualInput.remove(manualKey);
                  } else {
                    _showManualInput.add(manualKey);
                  }
                });
              },
              child: Text(
                hasManualOverride
                    ? 'smart_match.close_manual'.tr()
                    : 'smart_match.manual_input'.tr(),
                style: TextStyle(
                  color: hasManualOverride
                      ? AppColors.error
                      : AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// FOB 成本分解卡片（与网站 renderFOBResult 完全一致）
  Widget _buildFobBreakdownCards(FobEstimateResult fob) {
    final cur = fob.currency ?? 'CNY';
    final unt = fob.unit ?? 'common.unit_piece'.tr();
    final route = fob.fromCity != null && fob.toPort != null
        ? '${fob.fromCity}→${fob.toPort}'
        : '';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 工厂报价
        _buildFobCard(
          'smart_match.factory_price_label'.tr(),
          fob.costPrice.toStringAsFixed(2),
          cur,
          valueColor: AppColors.textTitle,
        ),
        // 国内运费
        _buildFobCard(
          'smart_match.domestic_freight'.tr(),
          (fob.domesticFreight > 0
                  ? fob.domesticFreight
                  : (fob.inlandFreight ?? 0))
              .toStringAsFixed(2),
          route.isNotEmpty ? route : cur,
          valueColor: const Color(0xFF45B7D1),
        ),
        // 港口杂费
        _buildFobCard(
          'smart_match.port_charges'.tr(),
          (fob.portCharges > 0 ? fob.portCharges : (fob.portFee ?? 0))
              .toStringAsFixed(2),
          cur,
          valueColor: const Color(0xFFFFD93D),
        ),
        // 报关费用
        _buildFobCard(
          'smart_match.customs_fee'.tr(),
          (fob.customsClearance > 0
                  ? fob.customsClearance
                  : (fob.customsFee ?? 0))
              .toStringAsFixed(2),
          cur,
          valueColor: AppColors.success,
        ),
        // 出口退税（与网站一致：未纳入计算）
        _buildFobCardSpecial(
          'smart_match.export_tax_rebate'.tr(),
          'smart_match.not_included'.tr(),
          'smart_match.export_tax_note'.tr(),
        ),
        // FOB价格（高亮）
        _buildFobCard(
          'smart_match.fob_price'.tr(),
          fob.displayFobPrice.toStringAsFixed(2),
          '$cur/$unt',
          valueColor: AppColors.primary,
          isHighlight: true,
          fontSize: 22,
        ),
      ],
    );
  }

  /// 单个FOB成本卡片
  Widget _buildFobCard(
    String title,
    String value,
    String subtitle, {
    Color? valueColor,
    bool isHighlight = false,
    double fontSize = 18,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textTitle,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 出口退税特殊卡片（与网站黄色虚线边框一致）
  Widget _buildFobCardSpecial(String title, String value, String note) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD93D).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFFD93D),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD93D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== 平台代采合同确认 ========================

  /// 显示平台代采合同确认页面（与网站 stage-contract-confirm 完全一致）
  void _showContractConfirm(SmartMatchState state) {
    final quote = state.factoryQuote;
    final fob = state.fobEstimate;
    final suppliers = quote?.supplierQuotes ?? [];
    final productName = state.productName.isNotEmpty ? state.productName : '-';
    final estimatedPrice = fob != null
        ? '¥${fob.displayFobPrice.toStringAsFixed(2)}'
        : (quote != null
              ? '¥${quote.quoteLow.toStringAsFixed(2)} ~ ¥${quote.quoteHigh.toStringAsFixed(2)}'
              : 'common.to_be_determined'.tr());

    // 佣金计算
    const platformFixedRate = 0.02;
    double contractAmount = 0;
    if (fob != null) {
      contractAmount = fob.displayFobPrice * 1000;
    } else if (suppliers.isNotEmpty) {
      final avg =
          suppliers.fold<double>(
            0,
            (sum, s) => sum + (s.quoteLow + s.quoteHigh) / 2,
          ) /
          suppliers.length;
      contractAmount = avg * 1000;
    }
    final platformFee = contractAmount * platformFixedRate;
    final rebateAmount = contractAmount * _rebateRate;
    final totalServiceFee = platformFee + rebateAmount;
    final pctVal = (_rebateRate * 100).round();

    bool agreed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D23),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // 拖拽指示条
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 标题
                Text(
                  'smart_match.contract_confirm_title'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ===== 平台代采模式说明 =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD93D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'smart_match.contract_mode_title'.tr(),
                        style: TextStyle(
                          color: Color(0xFFD4A00D),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildContractFeature(
                        '✅',
                        'smart_match.contract_sign'.tr(),
                        'smart_match.contract_sign_desc'.tr(),
                      ),
                      const SizedBox(height: 10),
                      _buildContractFeature(
                        '🔒',
                        'smart_match.contract_guarantee'.tr(),
                        'smart_match.contract_guarantee_desc'.tr(),
                      ),
                      const SizedBox(height: 10),
                      _buildContractFeature(
                        '🏭',
                        'smart_match.contract_supplier'.tr(),
                        'smart_match.contract_supplier_desc'.tr(),
                      ),
                      const SizedBox(height: 10),
                      _buildContractFeature(
                        '📦',
                        'smart_match.contract_quality'.tr(),
                        'smart_match.contract_quality_desc'.tr(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===== 合同信息预览 =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'smart_match.contract_preview_title'.tr(),
                        style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildContractInfoItem(
                              'smart_match.contract_type'.tr(),
                              'smart_match.contract_type_value'.tr(),
                              const Color(0xFFFFD93D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildContractInfoItem(
                              'smart_match.contract_party_b'.tr(),
                              'smart_match.contract_party_b_value'.tr(),
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildContractInfoItem(
                              'smart_match.purchase_product'.tr(),
                              productName,
                              AppColors.textTitle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildContractInfoItem(
                              'smart_match.estimated_amount'.tr(),
                              estimatedPrice,
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===== AI推荐供应商 =====
                if (suppliers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'smart_match.ai_recommended_suppliers'.tr(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...suppliers
                            .take(5)
                            .map(
                              (s) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.supplierName,
                                            style: const TextStyle(
                                              color: AppColors.textTitle,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (s.city != null)
                                            Text(
                                              '📍 ${s.city}',
                                              style: const TextStyle(
                                                color:
                                                    AppColors.textPlaceholder,
                                                fontSize: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${s.quoteLow.toStringAsFixed(2)} ~ ${s.quoteHigh.toStringAsFixed(2)} CNY',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'smart_match.final_supplier_note'.tr(),
                            style: TextStyle(
                              color: AppColors.textPlaceholder,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // ===== 协议勾选 =====
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: agreed,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setSheetState(() => agreed = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => agreed = !agreed),
                          child: Text(
                            'smart_match.agree_contract'.tr(),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===== 平台服务费摘要 =====
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'smart_match.service_fee_contract'.tr(),
                            style: TextStyle(
                              color: Color(0xFFFFD93D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'smart_match.service_fee_total'.tr(),
                            style: TextStyle(
                              color: AppColors.textPlaceholder,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '¥${totalServiceFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'smart_match.rebate_return_wallet'.tr(
                          args: ['$pctVal', rebateAmount.toStringAsFixed(2)],
                        ),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ===== 操作按钮 =====
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('smart_match.back_btn'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: agreed
                            ? () {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'smart_match.generating_contract'.tr(),
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                                // 跳转到合同签署页面（待实现）
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: AppColors.divider,
                          disabledForegroundColor: AppColors.textPlaceholder,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: agreed ? 4 : 0,
                        ),
                        child: Text(
                          'smart_match.confirm_generate'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 合同特性项
  Widget _buildContractFeature(String emoji, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 合同信息项
  Widget _buildContractInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ======================== 底部操作按钮 ========================

  Widget _buildBottomActions(SmartMatchState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(smartMatchProvider.notifier)
                        .goToStep(state.currentStep - 1);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('common.prev_step'.tr()),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _handleNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(_getNextButtonText(state)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextButtonText(SmartMatchState state) {
    switch (state.currentStep) {
      case 0:
        return state.matchedCategories.isEmpty
            ? 'smart_match.btn_start_match'.tr()
            : 'smart_match.btn_confirm_category'.tr();
      case 1:
        return 'smart_match.btn_start_cost'.tr();
      case 2:
        return 'smart_match.btn_view_quote'.tr();
      case 3:
        return 'smart_match.btn_get_fob'.tr();
      case 4:
        return state.fobEstimate == null
            ? 'smart_match.calc_fob'.tr()
            : 'smart_match.btn_complete'.tr();
      default:
        return 'common.next_step'.tr();
    }
  }

  void _handleNextStep() {
    final notifier = ref.read(smartMatchProvider.notifier);
    final state = ref.read(smartMatchProvider);

    switch (state.currentStep) {
      case 0:
        if (state.matchedCategories.isEmpty) {
          notifier.matchProduct();
        } else if (state.selectedCategoryCode != null) {
          notifier.proceedToStep2();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('smart_match.select_category_first'.tr())),
          );
        }
        break;
      case 1:
        // 表单验证: 检查必填参数
        final missingParams = <String>[];
        for (final param in state.costParameters) {
          if (param.required) {
            // 手动输入覆盖优先
            final manual = state.manualOverrides[param.parameterCode];
            final value = (manual != null && manual.isNotEmpty)
                ? manual
                : state.costParameterValues[param.parameterCode];
            if (value == null || value.toString().trim().isEmpty) {
              missingParams.add(param.parameterName);
            }
          }
        }
        if (missingParams.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'smart_match.fill_required'.tr(args: [missingParams.join('、')]),
              ),
            ),
          );
          return;
        }
        notifier.submitCostParams();
        break;
      case 2:
        notifier.loadFactoryQuote();
        break;
      case 3:
        notifier.loadFobParams();
        break;
      case 4:
        if (state.fobEstimate == null) {
          // FOB 参数验证（与网站 submitFOBEstimate 一致）
          final missingFob = <String>[];
          for (final param in state.fobParameters) {
            if (param.required) {
              final value = state.fobParameterValues[param.parameterCode];
              if (value == null || value.toString().trim().isEmpty) {
                missingFob.add(param.parameterName);
              }
            }
          }
          if (missingFob.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'smart_match.fill_required'.tr(args: [missingFob.join('、')]),
                ),
              ),
            );
            return;
          }
          notifier.submitFobParams();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('smart_match.flow_complete'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
        break;
    }
  }

  // ======================== 辅助方法 ========================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textTitle,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textPlaceholder,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.cardBg,
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(
                  'smart_match.take_photo'.tr(),
                  style: const TextStyle(color: AppColors.textTitle),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(fromCamera: true);
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: Text(
                  'smart_match.from_album'.tr(),
                  style: const TextStyle(color: AppColors.textTitle),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(fromCamera: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final service = ref.read(imageUploadServiceProvider);
    try {
      final url = fromCamera
          ? await service.pickFromCamera()
          : await service.pickFromGallery();
      if (url != null && url.isNotEmpty) {
        ref.read(smartMatchProvider.notifier).setImageUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('smart_match.image_upload_fail'.tr(args: ['$e'])),
          ),
        );
      }
    }
  }
}
