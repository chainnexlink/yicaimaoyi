import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import 'package:easy_localization/easy_localization.dart';

/// 帮助中心页 - 对标网站 help.html
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  int _expandedIndex = -1;

  List<Map<String, dynamic>> get _faqCategories => [
    {
      'icon': Icons.shopping_bag_outlined,
      'title': 'help.faq_category_purchase'.tr(),
      'color': AppColors.catBlue,
      'items': [
        {'q': 'help.faq_purchase_q1'.tr(), 'a': 'help.faq_purchase_a1'.tr()},
        {'q': 'help.faq_purchase_q2'.tr(), 'a': 'help.faq_purchase_a2'.tr()},
        {'q': 'help.faq_purchase_q3'.tr(), 'a': 'help.faq_purchase_a3'.tr()},
      ],
    },
    {
      'icon': Icons.gavel_outlined,
      'title': 'help.faq_category_auction'.tr(),
      'color': AppColors.featureYellow,
      'items': [
        {'q': 'help.faq_auction_q1'.tr(), 'a': 'help.faq_auction_a1'.tr()},
        {'q': 'help.faq_auction_q2'.tr(), 'a': 'help.faq_auction_a2'.tr()},
        {'q': 'help.faq_auction_q3'.tr(), 'a': 'help.faq_auction_a3'.tr()},
      ],
    },
    {
      'icon': Icons.local_shipping_outlined,
      'title': 'help.faq_category_order'.tr(),
      'color': AppColors.featureTeal,
      'items': [
        {'q': 'help.faq_order_q1'.tr(), 'a': 'help.faq_order_a1'.tr()},
        {'q': 'help.faq_order_q2'.tr(), 'a': 'help.faq_order_a2'.tr()},
        {'q': 'help.faq_order_q3'.tr(), 'a': 'help.faq_order_a3'.tr()},
      ],
    },
    {
      'icon': Icons.account_balance_wallet_outlined,
      'title': 'help.faq_category_payment'.tr(),
      'color': AppColors.secondary,
      'items': [
        {'q': 'help.faq_payment_q1'.tr(), 'a': 'help.faq_payment_a1'.tr()},
        {'q': 'help.faq_payment_q2'.tr(), 'a': 'help.faq_payment_a2'.tr()},
        {'q': 'help.faq_payment_q3'.tr(), 'a': 'help.faq_payment_a3'.tr()},
      ],
    },
    {
      'icon': Icons.security_outlined,
      'title': 'help.faq_category_account'.tr(),
      'color': AppColors.catPurple,
      'items': [
        {'q': 'help.faq_account_q1'.tr(), 'a': 'help.faq_account_a1'.tr()},
        {'q': 'help.faq_account_q2'.tr(), 'a': 'help.faq_account_a2'.tr()},
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
        title: Text('help.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.searchBarBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyM,
                decoration: InputDecoration(
                  hintText: 'help.search_hint'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textPlaceholder,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 快速入口
            Row(
              children: [
                _quickAction(
                  Icons.headset_mic_outlined,
                  'help.online_support'.tr(),
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _quickAction(
                  Icons.email_outlined,
                  'help.feedback'.tr(),
                  AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _quickAction(
                  Icons.phone_outlined,
                  'help.phone_consult'.tr(),
                  AppColors.featureTeal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // FAQ 分类
            ..._faqCategories.asMap().entries.map(
              (entry) => _buildFaqCategory(entry.key, entry.value),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCategory(int catIndex, Map<String, dynamic> category) {
    final items = category['items'] as List<Map<String, String>>;
    final color = category['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  category['title'] as String,
                  style: AppTextStyles.headingS,
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final globalIdx = catIndex * 100 + entry.key;
            final expanded = _expandedIndex == globalIdx;
            return Column(
              children: [
                const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 14,
                  endIndent: 14,
                ),
                GestureDetector(
                  onTap: () => setState(
                    () => _expandedIndex = expanded ? -1 : globalIdx,
                  ),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value['q']!,
                                style: AppTextStyles.bodyM.copyWith(
                                  color: AppColors.textTitle,
                                ),
                              ),
                            ),
                            Icon(
                              expanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 20,
                              color: AppColors.textPlaceholder,
                            ),
                          ],
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            entry.value['a']!,
                            style: AppTextStyles.bodyS.copyWith(height: 1.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
