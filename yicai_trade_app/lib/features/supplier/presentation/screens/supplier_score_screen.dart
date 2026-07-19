import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';

class SupplierScoreScreen extends ConsumerStatefulWidget {
  final int supplierId;
  const SupplierScoreScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierScoreScreen> createState() =>
      _SupplierScoreScreenState();
}

class _SupplierScoreScreenState extends ConsumerState<SupplierScoreScreen> {
  bool _isLoading = true;
  int _selectedFilter = 0; // 0=all, 1=excellent, 2=good, 3=pending

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('supplier.score_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOverviewCard(),
                  const SizedBox(height: 16),
                  _buildBadgeTierCard(),
                  const SizedBox(height: 16),
                  _buildScoreListSection(),
                  const SizedBox(height: 16),
                  _buildWeightAnalysis(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: 0.838,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.featureYellow,
                        ),
                      ),
                    ),
                    Text(
                      '838',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'supplier.overall_score'.tr(),
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x40FFD700), blurRadius: 16),
                    ],
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'supplier.gold_supplier'.tr(),
                  style: TextStyle(
                    color: AppColors.featureYellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Icon(
                    Icons.diamond_outlined,
                    size: 28,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'supplier.platinum_remaining'.tr(args: ['162']),
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('supplier.badge_tier'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: [
              _badgeTier(
                'supplier.badge_bronze'.tr(),
                Icons.shield,
                Color(0xFFCD7F32),
                '0-399',
                false,
              ),
              const SizedBox(width: 8),
              _badgeTier(
                'supplier.badge_silver'.tr(),
                Icons.shield,
                Color(0xFFC0C0C0),
                '400-699',
                false,
              ),
              const SizedBox(width: 8),
              _badgeTier(
                'supplier.badge_gold'.tr(),
                Icons.workspace_premium,
                Color(0xFFFFD700),
                '700-899',
                true,
              ),
              const SizedBox(width: 8),
              _badgeTier(
                'supplier.badge_platinum'.tr(),
                Icons.diamond,
                Color(0xFFE5E4E2),
                '900+',
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeTier(
    String name,
    IconData icon,
    Color color,
    String range,
    bool isCurrent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCurrent ? color.withValues(alpha: 0.1) : AppColors.pageBg,
          borderRadius: AppRadius.mdBorder,
          border: isCurrent
              ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrent ? color : AppColors.textSecondary,
              ),
            ),
            Text(
              range,
              style: TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreListSection() {
    final filters = [
      'common.all'.tr(),
      'supplier.score_excellent'.tr(),
      'supplier.score_good'.tr(),
      'supplier.score_pending_review'.tr(),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('supplier.order_score'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              filters.length,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filters[i]),
                  selected: _selectedFilter == i,
                  onSelected: (v) => setState(() => _selectedFilter = i),
                  selectedColor: AppColors.primarySurface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: _selectedFilter == i
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: _selectedFilter == i
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillBorder,
                  ),
                  side: BorderSide(
                    color: _selectedFilter == i
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (i) => _buildScoreItem(i)),
        ],
      ),
    );
  }

  Widget _buildScoreItem(int index) {
    final scores = [95, 88, 92, 76, 85];
    final orders = [
      'ORD-001234',
      'ORD-001189',
      'ORD-001156',
      'ORD-001098',
      'ORD-001045',
    ];
    final score = scores[index];
    Color scoreColor = score >= 90
        ? AppColors.success
        : score >= 80
        ? AppColors.primary
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orders[index],
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'supplier.score_media_count'.tr(
                    args: ['${20 + index * 5}', '${5 + index * 2}'],
                  ),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
                ClipRRect(
                  borderRadius: AppRadius.pillBorder,
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 4,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textPlaceholder),
        ],
      ),
    );
  }

  Widget _buildWeightAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'supplier.priority_benefits'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          _benefitItem(
            Icons.search,
            'supplier.benefit_search_priority'.tr(),
            'supplier.benefit_search_priority_desc'.tr(),
            true,
          ),
          _benefitItem(
            Icons.auto_awesome,
            'supplier.benefit_smart_match'.tr(),
            'supplier.benefit_smart_match_desc'.tr(),
            true,
          ),
          _benefitItem(
            Icons.home_outlined,
            'supplier.benefit_homepage'.tr(),
            'supplier.benefit_homepage_desc'.tr(),
            true,
          ),
          _benefitItem(
            Icons.verified,
            'supplier.benefit_badge'.tr(),
            'supplier.benefit_badge_desc'.tr(),
            true,
          ),
          _benefitItem(
            Icons.discount,
            'supplier.benefit_discount'.tr(),
            'supplier.benefit_discount_desc'.tr(),
            false,
          ),
        ],
      ),
    );
  }

  Widget _benefitItem(IconData icon, String title, String desc, bool unlocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: unlocked ? AppColors.primarySurface : AppColors.pageBg,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Icon(
              icon,
              size: 18,
              color: unlocked ? AppColors.primary : AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: unlocked
                        ? AppColors.textTitle
                        : AppColors.textPlaceholder,
                  ),
                ),
                Text(desc, style: AppTextStyles.caption),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outlined,
            size: 18,
            color: unlocked ? AppColors.success : AppColors.textPlaceholder,
          ),
        ],
      ),
    );
  }
}
