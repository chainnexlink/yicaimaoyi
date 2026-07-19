import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

/// 快速入口网格 V3 - 简洁双行图标网格
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(
        Icons.auto_awesome,
        'home.smart_match'.tr(),
        AppColors.primary,
        RouteNames.smartMatch,
      ),
      _QuickItem(
        Icons.gavel_rounded,
        'home.reverse_auction'.tr(),
        AppColors.secondary,
        RouteNames.auctionList,
      ),
      _QuickItem(
        Icons.monitor_heart_outlined,
        'home.production_monitor'.tr(),
        AppColors.featureTeal,
        RouteNames.productionMonitor,
      ),
      _QuickItem(
        Icons.receipt_long_outlined,
        'home.order_manage'.tr(),
        AppColors.catBlue,
        RouteNames.orders,
      ),
      _QuickItem(
        Icons.business_outlined,
        'home.supplier_library'.tr(),
        AppColors.catPurple,
        RouteNames.supplierList,
      ),
      _QuickItem(
        Icons.description_outlined,
        'home.contract_manage'.tr(),
        AppColors.catGreen,
        RouteNames.contractList,
      ),
      _QuickItem(
        Icons.question_answer_outlined,
        'home.inquiry_manage'.tr(),
        AppColors.catPink,
        RouteNames.inquiryList,
      ),
      _QuickItem(
        Icons.dashboard_outlined,
        'home.data_dashboard'.tr(),
        AppColors.catOrange,
        RouteNames.dashboard,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 0,
          childAspectRatio: 0.9,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(item.route),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textBody,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  _QuickItem(this.icon, this.label, this.color, this.route);
}
