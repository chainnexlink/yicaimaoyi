import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/contract_model.dart';
import '../providers/contract_provider.dart';

/// 合同详情页 - 对标网站 contract-detail.html
class ContractDetailScreen extends ConsumerStatefulWidget {
  final int contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractDetailScreen> createState() =>
      _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  ContractModel? _contract;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(contractRepositoryProvider);
      final contract = await repo.getContractDetail(widget.contractId);
      setState(() {
        _contract = contract;
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
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'contract.detail_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.textPlaceholder,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _load,
                    child: Text(
                      'common.retry'.tr(),
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final c = _contract!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 状态头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.statusColor.withValues(alpha: 0.12),
                    AppColors.cardBg,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: c.statusColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          c.statusLabel,
                          style: TextStyle(
                            color: c.statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\u00a5${c.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.priceL,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(c.title, style: AppTextStyles.headingM),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: c.contractNo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('contract.contract_no_copied'.tr()),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          '${'contract.contract_no'.tr()}: ${c.contractNo}',
                          style: AppTextStyles.bodyS,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 签约方信息
            _buildCard('contract.party_info'.tr(), [
              _row('contract.buyer_party'.tr(), c.buyerName),
              _row('contract.supplier_party'.tr(), c.supplierName),
            ]),
            const SizedBox(height: 12),

            // 合同条款
            _buildCard('contract.contract_terms'.tr(), [
              _row(
                'contract.contract_amount'.tr(),
                '\u00a5${c.amount.toStringAsFixed(2)}',
              ),
              if (c.startDate != null)
                _row('contract.start_date'.tr(), _fmt(c.startDate!)),
              if (c.endDate != null)
                _row('contract.end_date'.tr(), _fmt(c.endDate!)),
              if (c.paymentTerms != null)
                _row('contract.payment_terms'.tr(), c.paymentTerms!),
              if (c.deliveryTerms != null)
                _row('contract.delivery_terms'.tr(), c.deliveryTerms!),
            ]),
            const SizedBox(height: 12),

            // 操作按钮
            if (c.status == 'PENDING_SIGN')
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('contract.sign_coming'.tr())),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.lgBorder,
                    ),
                    child: Center(
                      child: Text(
                        'contract.sign_now'.tr(),
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
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
          Text(title, style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
