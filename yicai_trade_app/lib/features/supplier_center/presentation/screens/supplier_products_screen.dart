import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/supplier_center_provider.dart';
import '../../data/models/supplier_product_model.dart';

/// 供应商产品管理列表 - 对应网站 supplier-product-manage.html
class SupplierProductsScreen extends ConsumerStatefulWidget {
  const SupplierProductsScreen({super.key});

  @override
  ConsumerState<SupplierProductsScreen> createState() =>
      _SupplierProductsScreenState();
}

class _SupplierProductsScreenState
    extends ConsumerState<SupplierProductsScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supplierProductsProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(
          'supplier_center.products_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            onPressed: () => context.push(RouteNames.supplierProductEdit),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('ALL', 'supplier_center.products_all'.tr()),
      ('ACTIVE', 'supplier_center.products_active'.tr()),
      ('INACTIVE', 'supplier_center.products_inactive'.tr()),
      ('PENDING', 'supplier_center.products_review'.tr()),
    ];

    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = f.$1);
                ref
                    .read(supplierProductsProvider.notifier)
                    .loadProducts(status: f.$1 == 'ALL' ? null : f.$1);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : AppColors.searchBarBg,
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(SupplierProductsState state) {
    if (state.isLoading) {
      return const ListCardShimmer();
    }
    if (state.error != null) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        subtitle: state.error,
        onRetry: () => ref.read(supplierProductsProvider.notifier).refresh(),
      );
    }
    if (state.products.isEmpty) {
      return EmptyWidget(
        icon: Icons.inventory_2_outlined,
        message: 'supplier_center.no_products'.tr(),
        subtitle: 'supplier_center.add_first_product'.tr(),
        actionLabel: 'supplier_center.add_product'.tr(),
        onAction: () => context.push(RouteNames.supplierProductEdit),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBg,
      onRefresh: () => ref.read(supplierProductsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.products.length,
        itemBuilder: (context, index) =>
            _buildProductCard(state.products[index]),
      ),
    );
  }

  Widget _buildProductCard(SupplierProductModel product) {
    final statusColor = switch (product.status) {
      'ACTIVE' => AppColors.success,
      'INACTIVE' => AppColors.textPlaceholder,
      'PENDING' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final statusText = switch (product.status) {
      'ACTIVE' => 'supplier_center.products_active'.tr(),
      'INACTIVE' => 'supplier_center.products_inactive'.tr(),
      'PENDING' => 'supplier_center.products_review'.tr(),
      _ => product.status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.searchBarBg,
                borderRadius: AppRadius.mdBorder,
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: AppRadius.mdBorder,
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => const Icon(
                          Icons.image_outlined,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.textPlaceholder,
                    ),
            ),
            title: Text(
              product.name,
              style: AppTextStyles.bodyL.copyWith(
                color: AppColors.textTitle,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.category != null)
                  Text(
                    product.category!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.price != null)
                      Text(
                        '\u00a5${product.price!.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(fontSize: 15),
                      ),
                    if (product.unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        '/${product.unit}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => context.push(
              '${RouteNames.supplierProductEdit}?id=${product.id}',
            ),
          ),
          const Divider(
            height: 0.5,
            color: AppColors.divider,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.push(
                    '${RouteNames.supplierProductEdit}?id=${product.id}',
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    'supplier_center.edit_product'.tr(),
                    style: TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref
                      .read(supplierProductsProvider.notifier)
                      .toggleProductStatus(product.id),
                  icon: Icon(
                    product.status == 'ACTIVE'
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                  ),
                  label: Text(
                    product.status == 'ACTIVE'
                        ? 'supplier_center.take_down'.tr()
                        : 'supplier_center.put_up'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _confirmDelete(product),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    'common.delete'.tr(),
                    style: TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SupplierProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('common.confirm'.tr(), style: AppTextStyles.headingS),
        content: Text(
          'supplier_center.confirm_delete_product'.tr(args: [product.name]),
          style: AppTextStyles.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(supplierProductsProvider.notifier)
                  .deleteProduct(product.id);
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
