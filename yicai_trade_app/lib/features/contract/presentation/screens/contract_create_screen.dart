import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';

/// 合同创建页 - 对标网站 contract-create.html
/// 含模板选择、基本信息、合同明细、AI推荐供应商
class ContractCreateScreen extends ConsumerStatefulWidget {
  final int? orderId; // 可选：从订单创建合同
  const ContractCreateScreen({super.key, this.orderId});

  @override
  ConsumerState<ContractCreateScreen> createState() =>
      _ContractCreateScreenState();
}

class _ContractCreateScreenState extends ConsumerState<ContractCreateScreen> {
  int _selectedTemplate = 1; // 0标准, 1专业(推荐), 2企业
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarkController = TextEditingController();
  String _selectedUnit = 'pcs';
  DateTime? _deliveryDate;
  bool _agreeTerms = false;

  // Unit key mappings for i18n
  static const _unitKeys = ['contract.unit_pcs', 'contract.unit_set', 'contract.unit_ton', 'contract.unit_box', 'contract.unit_lot'];
  static const _unitValues = ['pcs', 'set', 'ton', 'box', 'lot'];

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _remarkController.dispose();
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
        title: Text(
          'contract.create_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformNotice(),
            const SizedBox(height: 16),
            _buildTemplateSelection(),
            const SizedBox(height: 16),
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildAiSuppliersCard(),
            const SizedBox(height: 16),
            _buildContractDetailsForm(),
            const SizedBox(height: 16),
            _buildContractPreview(),
            const SizedBox(height: 16),
            _buildAgreementAndSubmit(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'contract.platform_contract'.tr(),
                style: AppTextStyles.headingS.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            'contract.platform_contract_desc',
            'contract.escrow_payment',
            'contract.production_monitor',
            'contract.dispute_resolution',
          ].map(
            (key) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    key.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('contract.select_template'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: [
              _templateCard(
                0,
                'contract.template_standard'.tr(),
                'contract.template_standard_desc'.tr(),
                Icons.description_outlined,
                null,
              ),
              const SizedBox(width: 8),
              _templateCard(
                1,
                'contract.template_pro'.tr(),
                'contract.template_pro_desc'.tr(),
                Icons.verified_outlined,
                'contract.template_recommended'.tr(),
              ),
              const SizedBox(width: 8),
              _templateCard(
                2,
                'contract.template_enterprise'.tr(),
                'contract.template_enterprise_desc'.tr(),
                Icons.business_outlined,
                null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateCard(
    int index,
    String name,
    String desc,
    IconData icon,
    String? badge,
  ) {
    final isSelected = _selectedTemplate == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTemplate = index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.pageBg,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('contract.basic_info'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          _infoRow(
            'contract.contract_type'.tr(),
            'contract.platform_contract'.tr(),
          ),
          _infoRow('contract.buyer_label'.tr(), 'contract.buyer_hint'.tr()),
          _infoRow(
            'contract.product_name_label'.tr(),
            'contract.product_name_value'.tr(),
          ),
          _infoRow(
            'contract.product_category_label'.tr(),
            'contract.product_category_value'.tr(),
          ),
          _infoRow('contract.estimated_amount'.tr(), '\u00a555,300.00'),
          if (widget.orderId != null)
            _infoRow('contract.related_order'.tr(), 'ORD-${widget.orderId}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.bodyS)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuppliersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text('contract.ai_suppliers'.tr(), style: AppTextStyles.headingS),
            ],
          ),
          const SizedBox(height: 12),
          _supplierRecommend('contract.demo_supplier_1'.tr(), 'contract.demo_city_1'.tr(), '\u00a5270~300/${'contract.unit_pcs'.tr()}', 4.8),
          const Divider(height: 16),
          _supplierRecommend('contract.demo_supplier_2'.tr(), 'contract.demo_city_2'.tr(), '\u00a5250~280/${'contract.unit_pcs'.tr()}', 4.6),
          const Divider(height: 16),
          _supplierRecommend('contract.demo_supplier_3'.tr(), 'contract.demo_city_3'.tr(), '\u00a5290~310/${'contract.unit_pcs'.tr()}', 4.7),
        ],
      ),
    );
  }

  Widget _supplierRecommend(
    String name,
    String city,
    String priceRange,
    double rating,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySurface,
          child: Text(
            name.substring(0, 1),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
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
              Text('$city | $priceRange', style: AppTextStyles.caption),
            ],
          ),
        ),
        Row(
          children: [
            Icon(Icons.star, size: 14, color: AppColors.featureYellow),
            const SizedBox(width: 2),
            Text(
              '$rating',
              style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContractDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('contract.contract_detail'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          // 数量
          _formField(
            'contract.quantity_label'.tr(),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'contract.quantity_hint'.tr(),
                      filled: true,
                      fillColor: AppColors.pageBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBorder,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      items: _unitValues
                          .asMap()
                          .entries
                          .map(
                            (e) => DropdownMenuItem(value: e.value, child: Text(_unitKeys[e.key].tr())),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedUnit = v ?? 'pcs'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 交货日期
          _formField(
            'contract.delivery_date'.tr(),
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 15)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _deliveryDate = date);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _deliveryDate != null
                            ? '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}'
                            : 'contract.delivery_date_hint'.tr(),
                        style: _deliveryDate != null
                            ? AppTextStyles.bodyM
                            : AppTextStyles.bodyM.copyWith(
                                color: AppColors.textPlaceholder,
                              ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 交货地址
          _formField(
            'contract.delivery_address'.tr(),
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'contract.delivery_address_hint'.tr(),
                filled: true,
                fillColor: AppColors.pageBg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdBorder,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 备注
          _formField(
            'contract.remark_label'.tr(),
            child: TextField(
              controller: _remarkController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'contract.remark_hint'.tr(),
                filled: true,
                fillColor: AppColors.pageBg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdBorder,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildContractPreview() {
    final templateKeys = [
      'contract.template_standard',
      'contract.template_pro',
      'contract.template_enterprise',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'contract.contract_preview'.tr(),
                style: AppTextStyles.headingS,
              ),
              Text(
                '${templateKeys[_selectedTemplate].tr()}${'contract.template'.tr()}',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.divider),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'contract.platform_contract'.tr(),
                      style: AppTextStyles.headingM,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${'contract.contract_no_label'.tr()}: CT-XXXX-XXXX',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'contract.clause_purpose'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'contract.clause_purpose_text'.tr(),
                    style: AppTextStyles.bodyS,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'contract.clause_product'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${'contract.preview_product_name'.tr()}: ${'contract.preview_product_a'.tr()}\n${'contract.preview_quantity'.tr()}: ${_quantityController.text.isEmpty ? "___" : _quantityController.text} ${_unitKeys[_unitValues.indexOf(_selectedUnit)].tr()}',
                    style: AppTextStyles.bodyS,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'contract.clause_payment'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'contract.clause_payment_text'.tr(),
                    style: AppTextStyles.bodyS,
                  ),
                  if (_selectedTemplate >= 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'contract.clause_quality'.tr(),
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'contract.clause_quality_text'.tr(),
                      style: AppTextStyles.bodyS,
                    ),
                  ],
                  if (_selectedTemplate >= 2) ...[
                    const SizedBox(height: 8),
                    Text(
                      'contract.clause_liability'.tr(),
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'contract.clause_liability_text'.tr(),
                      style: AppTextStyles.bodyS,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementAndSubmit() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                child: Text.rich(
                  TextSpan(
                    text: 'contract.agree_terms'.tr(),
                    style: AppTextStyles.bodyS,
                    children: [
                      TextSpan(
                        text: 'contract.service_agreement'.tr(),
                        style: TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(text: 'contract.and'.tr()),
                      TextSpan(
                        text: 'contract.contract_terms_doc'.tr(),
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
                child: Text('contract.back_to_edit'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _agreeTerms ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
                child: Text(
                  'contract.confirm_submit'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
