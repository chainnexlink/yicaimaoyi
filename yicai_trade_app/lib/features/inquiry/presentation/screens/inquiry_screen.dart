import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/inquiry_model.dart';
import '../providers/inquiry_provider.dart';

/// 询盘管理页面 - 真实 API 数据
class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key});

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabKeys = [
    'inquiry.all',
    'inquiry.pending',
    'inquiry.quoted',
    'inquiry.closed',
  ];
  static const _tabStatuses = [null, 'PENDING', 'QUOTED', 'CLOSED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabKeys.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(
      () => ref.read(inquiryListProvider.notifier).loadInquiries(),
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final status = _tabStatuses[_tabController.index];
      ref.read(inquiryListProvider.notifier).loadInquiries(status: status);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
        title: Text('inquiry.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: _tabKeys.map((t) => Tab(text: t.tr())).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('inquiry.send_inquiry'.tr()),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.send_rounded, color: AppColors.textOnPrimary),
        label: Text(
          'inquiry.send_inquiry'.tr(),
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabKeys.map((t) => _InquiryTabView(tab: t)).toList(),
      ),
    );
  }
}

class _InquiryTabView extends ConsumerWidget {
  final String tab;
  const _InquiryTabView({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inquiryListProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.inquiries.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => ref.read(inquiryListProvider.notifier).refresh(),
          child: Text(
            'common.retry'.tr(),
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      );
    }

    if (state.inquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: AppColors.textPlaceholder.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'inquiry.no_inquiries'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(inquiryListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.inquiries.length,
        itemBuilder: (context, i) => _InquiryCard(inquiry: state.inquiries[i]),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final InquiryModel inquiry;
  const _InquiryCard({required this.inquiry});

  Color get _statusColor {
    switch (inquiry.status) {
      case 'PENDING':
        return AppColors.warning;
      case 'QUOTED':
        return AppColors.success;
      case 'CLOSED':
        return AppColors.textSecondary;
      case 'ACCEPTED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'inquiry.inquiry_detail'.tr(args: [inquiry.productName]),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppRadius.lgBorder,
          boxShadow: AppShadows.cardSmall,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inquiry.productName,
                    style: AppTextStyles.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTitle,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inquiry.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'inquiry.sent_to'.tr(args: [inquiry.supplierName]),
              style: AppTextStyles.bodyS,
            ),
            const SizedBox(height: 4),
            Text(
              'inquiry.quantity_date'.tr(
                args: [
                  inquiry.quantity,
                  inquiry.createdAt != null
                      ? '${inquiry.createdAt!.month}${'common.month_unit'.tr()}${inquiry.createdAt!.day}${'common.day_unit'.tr()}'
                      : '',
                ],
              ),
              style: AppTextStyles.caption,
            ),
            if (inquiry.quotedPrice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'inquiry.quote_price'.tr(
                        args: [inquiry.quotedPrice!.toStringAsFixed(2)],
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const Spacer(),
                    if (inquiry.deliveryDays != null)
                      Text(
                        'inquiry.delivery_days'.tr(
                          args: ['${inquiry.deliveryDays}'],
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
