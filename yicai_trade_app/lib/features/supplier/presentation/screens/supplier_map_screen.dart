import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';

class SupplierMapScreen extends ConsumerStatefulWidget {
  const SupplierMapScreen({super.key});

  @override
  ConsumerState<SupplierMapScreen> createState() => _SupplierMapScreenState();
}

class _SupplierMapScreenState extends ConsumerState<SupplierMapScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('supplier.map_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.divider,
          isScrollable: true,
          tabs: [
            Tab(text: 'supplier.map_tab_global'.tr()),
            Tab(text: 'supplier.map_tab_china'.tr()),
            Tab(text: 'supplier.map_tab_industry'.tr()),
            Tab(text: 'supplier.map_tab_comparison'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalTab(),
          _buildChinaTab(),
          _buildIndustryTab(),
          _buildComparisonTab(),
        ],
      ),
    );
  }

  Widget _buildGlobalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRegionStats(),
          const SizedBox(height: 16),
          _buildMapPlaceholder('supplier.map_global_distribution'.tr()),
          const SizedBox(height: 16),
          _buildHotRegions(),
        ],
      ),
    );
  }

  Widget _buildChinaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMapPlaceholder('supplier.map_china_distribution'.tr()),
          const SizedBox(height: 16),
          _buildProvincialList(),
        ],
      ),
    );
  }

  Widget _buildIndustryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [_buildIndustryCards()]),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [_buildComparisonTable()]),
    );
  }

  Widget _buildRegionStats() {
    final regions = [
      ('supplier.map_region_south'.tr(), 1280, AppColors.primary),
      ('supplier.map_region_east'.tr(), 960, AppColors.featureTeal),
      ('supplier.map_region_north'.tr(), 540, AppColors.secondary),
      ('supplier.map_region_overseas'.tr(), 320, AppColors.catPurple),
    ];
    return Row(
      children: regions.map((r) {
        final (name, count, color) = r;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Column(
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: AppRadius.pillBorder,
                  child: LinearProgressIndicator(
                    value: count / 1500,
                    minHeight: 4,
                    backgroundColor: AppColors.pageBg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapPlaceholder(String title) {
    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.headingS.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'supplier.map_click_hint'.tr(),
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                [
                      'supplier.map_city_shenzhen'.tr(),
                      'supplier.map_city_dongguan'.tr(),
                      'supplier.map_city_guangzhou'.tr(),
                      'supplier.map_city_foshan'.tr(),
                      'supplier.map_city_yiwu'.tr(),
                      'supplier.map_city_suzhou'.tr(),
                      'supplier.map_city_shanghai'.tr(),
                    ]
                    .map(
                      (city) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: AppRadius.pillBorder,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          city,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHotRegions() {
    final regions = [
      (
        'supplier.map_country_china'.tr(),
        [
          'supplier.map_city_shenzhen'.tr(),
          'supplier.map_city_dongguan'.tr(),
          'supplier.map_city_guangzhou'.tr(),
          'supplier.map_city_foshan'.tr(),
          'supplier.map_city_yiwu'.tr(),
        ],
      ),
      (
        'supplier.map_region_southeast_asia'.tr(),
        [
          'supplier.map_country_vietnam'.tr(),
          'supplier.map_country_thailand'.tr(),
          'supplier.map_country_indonesia'.tr(),
        ],
      ),
      (
        'supplier.map_region_europe'.tr(),
        [
          'supplier.map_country_germany'.tr(),
          'supplier.map_country_italy'.tr(),
          'supplier.map_country_turkey'.tr(),
        ],
      ),
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
          Text('supplier.map_hot_regions'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          ...regions.map((r) {
            final (region, cities) = r;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region,
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: cities
                        .map(
                          (c) => InkWell(
                            onTap: () => context.push(RouteNames.supplierList),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pageBg,
                                borderRadius: AppRadius.mdBorder,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(c, style: AppTextStyles.bodyS),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 14,
                                    color: AppColors.textPlaceholder,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProvincialList() {
    final provinces = [
      (
        'supplier.map_province_guangdong'.tr(),
        680,
        'supplier.map_industries_guangdong'.tr(),
      ),
      (
        'supplier.map_province_zhejiang'.tr(),
        520,
        'supplier.map_industries_zhejiang'.tr(),
      ),
      (
        'supplier.map_province_jiangsu'.tr(),
        440,
        'supplier.map_industries_jiangsu'.tr(),
      ),
      (
        'supplier.map_province_fujian'.tr(),
        280,
        'supplier.map_industries_fujian'.tr(),
      ),
      (
        'supplier.map_province_shandong'.tr(),
        240,
        'supplier.map_industries_shandong'.tr(),
      ),
      (
        'supplier.map_province_hebei'.tr(),
        180,
        'supplier.map_industries_hebei'.tr(),
      ),
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
          Text(
            'supplier.map_province_distribution'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          ...provinces.map((p) {
            final (name, count, industries) = p;
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
                          name,
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(industries, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    'supplier.map_company_count'.tr(args: ['$count']),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textPlaceholder,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIndustryCards() {
    final industries = [
      (
        'supplier.map_industry_hardware'.tr(),
        450,
        28.5,
        Icons.build_outlined,
        AppColors.primary,
      ),
      (
        'supplier.map_industry_electronics'.tr(),
        380,
        24.1,
        Icons.memory_outlined,
        AppColors.featureTeal,
      ),
      (
        'supplier.map_industry_textile'.tr(),
        290,
        18.4,
        Icons.checkroom_outlined,
        AppColors.secondary,
      ),
      (
        'supplier.map_industry_machinery'.tr(),
        220,
        13.9,
        Icons.precision_manufacturing_outlined,
        AppColors.catPurple,
      ),
      (
        'supplier.map_industry_chemicals'.tr(),
        140,
        8.9,
        Icons.science_outlined,
        AppColors.warning,
      ),
      (
        'supplier.map_industry_other'.tr(),
        100,
        6.2,
        Icons.category_outlined,
        AppColors.textSecondary,
      ),
    ];

    return Column(
      children: industries.map((ind) {
        final (name, count, pct, icon, color) = ind;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'supplier.map_company_count_pct'.tr(
                            args: ['$count', '$pct'],
                          ),
                          style: AppTextStyles.bodyS,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: AppRadius.pillBorder,
                      child: LinearProgressIndicator(
                        value: pct / 30,
                        minHeight: 6,
                        backgroundColor: AppColors.pageBg,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonTable() {
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
            'supplier.map_tab_comparison'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'supplier.map_dimension'.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'supplier.map_region_south'.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'supplier.map_region_east'.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'supplier.map_region_north'.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          _compRow('supplier.map_supplier_count'.tr(), '1280', '960', '540'),
          _compRow('supplier.map_avg_rating'.tr(), '4.6', '4.5', '4.3'),
          _compRow(
            'supplier.map_avg_delivery'.tr(),
            'supplier.map_days'.tr(args: ['12']),
            'supplier.map_days'.tr(args: ['15']),
            'supplier.map_days'.tr(args: ['18']),
          ),
          _compRow(
            'supplier.map_avg_quote'.tr(),
            'supplier.map_level_medium'.tr(),
            'supplier.map_level_medium_high'.tr(),
            'supplier.map_level_low'.tr(),
          ),
          _compRow(
            'supplier.map_response_speed'.tr(),
            'supplier.map_level_fast'.tr(),
            'supplier.map_level_medium'.tr(),
            'supplier.map_level_medium'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _compRow(String label, String v1, String v2, String v3) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodyS)),
          Expanded(
            child: Text(
              v1,
              style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              v2,
              style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              v3,
              style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
