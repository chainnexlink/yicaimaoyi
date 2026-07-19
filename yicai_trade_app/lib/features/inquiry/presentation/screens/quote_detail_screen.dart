import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/inquiry_provider.dart';

/// 报价详情页 - 对标网站 quote-detail.html
class QuoteDetailScreen extends ConsumerWidget {
  final int quoteId;
  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('inquiry.quote_detail'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: Text('inquiry.share_quote'.tr()),
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('inquiry.share_coming'.tr()),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text('inquiry.report_issue'.tr()),
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('inquiry.report_submitted'.tr()),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inquiryListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 12),
              _buildComparisonBar(),
              const SizedBox(height: 16),
              _buildSupplierInfoCard(),
              const SizedBox(height: 12),
              _buildQuoteDetailsCard(),
              const SizedBox(height: 12),
              _buildPriceSummaryCard(),
              const SizedBox(height: 12),
              _buildQuoteNotesCard(),
              const SizedBox(height: 12),
              _buildOtherQuotesCard(),
              const SizedBox(height: 12),
              _buildRelatedDemandCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildActionBar(context, ref),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.pillBorder,
            ),
            child: Text(
              'inquiry.pending_confirm'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'inquiry.quote_no'.tr()}: QT-${quoteId.toString().padLeft(6, '0')}',
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${'inquiry.quote_time'.tr()}: 2026-03-20 14:30',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.timer_outlined, size: 20, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            'inquiry.expires_in'.tr(args: ['3']),
            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Row(
        children: [
          _comparisonItem(
            'inquiry.total_amount'.tr(),
            '\u00a528,500',
            AppColors.textPrice,
          ),
          _divider(),
          _comparisonItem(
            'inquiry.unit_price'.tr(),
            '\u00a5285/${'inquiry.demo_pcs'.tr()}',
            AppColors.textTitle,
          ),
          _divider(),
          _comparisonItem(
            'inquiry.delivery_period'.tr(),
            'inquiry.demo_days'.tr(args: ['15']),
            AppColors.featureTeal,
          ),
          _divider(),
          _comparisonItem(
            'inquiry.rating'.tr(),
            '4.8',
            AppColors.featureYellow,
          ),
        ],
      ),
    );
  }

  Widget _comparisonItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.divider);

  Widget _buildSupplierInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('inquiry.supplier_info'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  'S',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
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
                        Text(
                          'inquiry.supplier_a'.tr(),
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.featureYellowSurface,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Text(
                            'inquiry.certified'.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.featureYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'inquiry.supplier_location'.tr(),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _supplierStat('inquiry.rating'.tr(), '4.8'),
              _supplierStat('inquiry.orders'.tr(), '156'),
              _supplierStat('inquiry.deal_rate'.tr(), '92%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplierStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: AppRadius.mdBorder,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('inquiry.quote_breakdown'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          _quoteItem('inquiry.demo_product_a'.tr(), '100${'inquiry.demo_pcs'.tr()}', '\u00a5285.00', '\u00a528,500'),
          const Divider(height: 16),
          _quoteItem('inquiry.demo_mold_fee'.tr(), '1${'inquiry.demo_set'.tr()}', '\u00a53,000.00', '\u00a53,000'),
          const Divider(height: 16),
          _quoteItem('inquiry.demo_packaging_fee'.tr(), '100${'inquiry.demo_pcs'.tr()}', '\u00a55.00', '\u00a5500'),
        ],
      ),
    );
  }

  Widget _quoteItem(String name, String qty, String unit, String total) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text('$qty x $unit', style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(
          total,
          style: AppTextStyles.bodyM.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrice,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        children: [
          _priceRow('inquiry.subtotal'.tr(), '\u00a528,500.00'),
          _priceRow('inquiry.shipping'.tr(), '\u00a5800.00'),
          _priceRow('inquiry.tax'.tr(), '\u00a52,376.00'),
          _priceRow('inquiry.discount'.tr(), '-\u00a5500.00', isDiscount: true),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('inquiry.total'.tr(), style: AppTextStyles.headingS),
              Text('\u00a531,176.00', style: AppTextStyles.priceL),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyM),
          Text(
            value,
            style: AppTextStyles.bodyM.copyWith(
              color: isDiscount ? AppColors.success : AppColors.textTitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('inquiry.quote_notes'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          _noteItem(
            Icons.local_shipping_outlined,
            'inquiry.note_shipping'.tr(),
          ),
          _noteItem(Icons.verified_outlined, 'inquiry.note_warranty'.tr()),
          _noteItem(Icons.payment_outlined, 'inquiry.note_payment'.tr()),
          _noteItem(Icons.schedule_outlined, 'inquiry.note_validity'.tr()),
        ],
      ),
    );
  }

  Widget _noteItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyM)),
        ],
      ),
    );
  }

  Widget _buildOtherQuotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('inquiry.other_quotes'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          _otherQuoteItem('inquiry.demo_supplier_b'.tr(), '\u00a530,200', 'inquiry.demo_days'.tr(args: ['18']), '4.5'),
          const Divider(height: 12),
          _otherQuoteItem('inquiry.demo_supplier_c'.tr(), '\u00a532,800', 'inquiry.demo_days'.tr(args: ['12']), '4.9'),
          const Divider(height: 12),
          _otherQuoteItem('inquiry.demo_supplier_d'.tr(), '\u00a527,500', 'inquiry.demo_days'.tr(args: ['20']), '4.2'),
        ],
      ),
    );
  }

  Widget _otherQuoteItem(
    String name,
    String price,
    String delivery,
    String rating,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.pageBg,
          child: Text(
            name.substring(name.length - 1),
            style: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${'inquiry.delivery_period'.tr()}$delivery | ${'inquiry.rating'.tr()}$rating',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Text(
          price,
          style: AppTextStyles.bodyM.copyWith(
            color: AppColors.textPrice,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedDemandCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('inquiry.related_demand'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'inquiry.demand_no'.tr(args: ['DM-001234']),
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'inquiry.demand_summary'.tr(),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textPlaceholder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('inquiry.confirm_reject_title'.tr()),
                      content: Text('inquiry.confirm_reject_content'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('common.cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('inquiry.quote_rejected'.tr()),
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'inquiry.reject_quote'.tr(),
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
                child: Text(
                  'inquiry.reject_quote'.tr(),
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('inquiry.negotiate_coming'.tr())),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
                child: Text(
                  'inquiry.negotiate'.tr(),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('inquiry.confirm_accept_title'.tr()),
                      content: Text('inquiry.confirm_accept_content'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('common.cancel'.tr()),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('inquiry.quote_accepted'.tr()),
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text('common.confirm'.tr()),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
                child: Text(
                  'inquiry.accept_quote'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
