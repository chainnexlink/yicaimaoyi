import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final int supplierId;
  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  SupplierModel? _supplier;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSupplier();
  }

  Future<void> _loadSupplier() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(supplierRepositoryProvider);
      final supplier = await repo.getSupplierDetail(widget.supplierId);
      setState(() {
        _supplier = supplier;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: 12),
          Text(
            'common.load_failed'.tr(),
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          TextButton(
            onPressed: _loadSupplier,
            child: Text(
              'common.retry'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _supplier!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.pageBg,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 3),
                      ),
                      child: s.logoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                s.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _logoPlaceholder(s),
                              ),
                            )
                          : _logoPlaceholder(s),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.name,
                      style: AppTextStyles.headingL.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (s.location != null)
                      Text(
                        s.location!,
                        style: AppTextStyles.bodyS.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildRatingCard(s),
              const SizedBox(height: 12),
              _buildMetricsCard(s),
              const SizedBox(height: 12),
              _buildCategoriesCard(s),
              const SizedBox(height: 12),
              if (s.description != null && s.description!.isNotEmpty) ...[
                _buildDescriptionCard(s),
                const SizedBox(height: 12),
              ],
              _buildContactCard(s),
              const SizedBox(height: 12),
              _buildActions(s),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard(SupplierModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                s.rating.toStringAsFixed(1),
                style: AppTextStyles.statNumber,
              ),
              Row(
                children: List.generate(5, (i) {
                  final full = i < s.rating.floor();
                  final half = !full && i < s.rating;
                  return Icon(
                    full
                        ? Icons.star_rounded
                        : half
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: AppColors.featureYellow,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _ratingBar('supplier.quality_score'.tr(), 0.9),
                const SizedBox(height: 8),
                _ratingBar('supplier.delivery_score'.tr(), 0.85),
                const SizedBox(height: 8),
                _ratingBar('supplier.service_score'.tr(), 0.88),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, double value) {
    return Row(
      children: [
        SizedBox(width: 32, child: Text(label, style: AppTextStyles.caption)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildMetricsCard(SupplierModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Row(
        children: [
          _metric(
            'supplier.completed_orders'.tr(),
            '${s.orderCount}',
            AppColors.primary,
          ),
          _metricDivider(),
          _metric(
            'supplier.response_time'.tr(),
            s.responseTime ?? '-',
            AppColors.featureTeal,
          ),
          _metricDivider(),
          _metric(
            'supplier.on_time_rate'.tr(),
            s.onTimeRate ?? '-',
            AppColors.success,
          ),
          _metricDivider(),
          _metric(
            'supplier.quality_rate'.tr(),
            s.qualityRate ?? '-',
            AppColors.featureYellow,
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _metricDivider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Widget _buildCategoriesCard(SupplierModel s) {
    if (s.categories.isEmpty) return const SizedBox.shrink();
    final colors = [
      AppColors.catBlue,
      AppColors.catOrange,
      AppColors.catGreen,
      AppColors.catPurple,
      AppColors.catPink,
      AppColors.catTeal,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('supplier.main_products'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: s.categories.asMap().entries.map((e) {
              final color = colors[e.key % colors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(SupplierModel s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('supplier.company_intro'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 10),
          Text(
            s.description!,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(SupplierModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('supplier.contact_info'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          if (s.contactName != null)
            _contactRow(
              Icons.person_outline_rounded,
              'supplier.contact_person'.tr(),
              s.contactName!,
            ),
          if (s.contactPhone != null)
            _contactRow(
              Icons.phone_outlined,
              'supplier.contact_phone'.tr(),
              s.contactPhone!,
            ),
          if (s.certified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'common.platform_certified'.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(SupplierModel s) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(RouteNames.inquiryList),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.lgBorder,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: AppColors.textOnPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'supplier.send_inquiry'.tr(),
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(RouteNames.chat),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: AppRadius.lgBorder,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'supplier.online_chat'.tr(),
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoPlaceholder(SupplierModel s) {
    return Center(
      child: Text(
        s.name.isNotEmpty ? s.name[0] : '?',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
