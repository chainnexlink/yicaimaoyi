import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(supplierListProvider.notifier).loadSuppliers(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierListProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('supplier.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'supplier.search_hint'.tr(),
                hintStyle: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textPlaceholder,
                ),
                filled: true,
                fillColor: AppColors.pageBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (v) =>
                  ref.read(supplierListProvider.notifier).search(v),
            ),
          ),
          Container(
            color: AppColors.cardBg,
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children:
                  [
                    'supplier.sort_comprehensive'.tr(),
                    'supplier.sort_highest_rating'.tr(),
                    'supplier.sort_shortest_delivery'.tr(),
                    'common.certified'.tr(),
                  ].asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    final selected = _selectedFilter == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : AppColors.textBody,
                          ),
                        ),
                        selected: selected,
                        onSelected: (v) {
                          setState(() => _selectedFilter = idx);
                          ref
                              .read(supplierListProvider.notifier)
                              .loadSuppliers(
                                keyword: _searchController.text.isEmpty
                                    ? null
                                    : _searchController.text,
                                sortBy: idx == 0 ? null : label,
                              );
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.pageBg,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(child: _buildList(state)),
        ],
      ),
    );
  }

  Widget _buildList(SupplierListState state) {
    if (state.isLoading) {
      return const ListCardShimmer();
    }

    if (state.error != null && state.suppliers.isEmpty) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        onRetry: () => ref.read(supplierListProvider.notifier).refresh(),
      );
    }

    if (state.suppliers.isEmpty) {
      return EmptyWidget(
        icon: Icons.store_outlined,
        message: 'supplier.no_suppliers'.tr(),
        subtitle: 'supplier.no_suppliers_subtitle'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(supplierListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.suppliers.length,
        itemBuilder: (context, i) =>
            _SupplierCard(supplier: state.suppliers[i]),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  const _SupplierCard({required this.supplier});

  Color get _color {
    final colors = [
      AppColors.primary,
      AppColors.featureTeal,
      AppColors.catPurple,
      AppColors.secondary,
      AppColors.success,
    ];
    return colors[supplier.id % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/suppliers/${supplier.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppRadius.lgBorder,
          boxShadow: AppShadows.cardSmall,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: supplier.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              supplier.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => Center(
                                child: Text(
                                  supplier.name.isNotEmpty
                                      ? supplier.name[0]
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _color,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              supplier.name.isNotEmpty ? supplier.name[0] : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _color,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                supplier.name,
                                style: AppTextStyles.bodyL.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTitle,
                                ),
                              ),
                            ),
                            if (supplier.certified) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                        if (supplier.location != null)
                          Text(
                            supplier.location!,
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.featureYellow,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${supplier.rating}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.featureYellow,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'supplier.order_count'.tr(
                          args: ['${supplier.orderCount}'],
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (supplier.categories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: supplier.categories
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  if (supplier.responseTime != null)
                    _buildIndicator(
                      'supplier.response_time'.tr(),
                      supplier.responseTime!,
                      AppColors.featureTeal,
                    ),
                  if (supplier.onTimeRate != null)
                    _buildIndicator(
                      'supplier.on_time_rate'.tr(),
                      supplier.onTimeRate!,
                      AppColors.success,
                    ),
                  if (supplier.qualityRate != null)
                    _buildIndicator(
                      'supplier.quality_rate'.tr(),
                      supplier.qualityRate!,
                      AppColors.primary,
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'supplier.inquiry_message'.tr(
                              args: [supplier.name],
                            ),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppColors.primarySurface,
                    ),
                    child: Text(
                      'supplier.send_inquiry'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
          ),
        ],
      ),
    );
  }
}
