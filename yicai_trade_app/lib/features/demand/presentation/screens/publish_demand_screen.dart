import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 发布需求页面 - 表单验证 + API 提交
class PublishDemandScreen extends ConsumerStatefulWidget {
  const PublishDemandScreen({super.key});

  @override
  ConsumerState<PublishDemandScreen> createState() =>
      _PublishDemandScreenState();
}

class _PublishDemandScreenState extends ConsumerState<PublishDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _specController = TextEditingController();
  final _quantityController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDelivery;
  String? _selectedTrade;
  String? _selectedRegion;
  bool _requireCertified = false;
  bool _requireISO = false;
  bool _supportSmallBatch = false;
  bool _supportOEM = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _specController.dispose();
    _quantityController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('demand.title_required'.tr())));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiConstants.demands,
        data: {
          'title': _titleController.text.trim(),
          'category': _selectedCategory,
          'specification': _specController.text.trim(),
          'quantity': _quantityController.text.trim(),
          'budget': _budgetController.text.trim(),
          'deliveryPeriod': _selectedDelivery,
          'tradeTerms': _selectedTrade,
          'supplierRegion': _selectedRegion,
          'requireCertified': _requireCertified,
          'requireISO': _requireISO,
          'supportSmallBatch': _supportSmallBatch,
          'supportOEM': _supportOEM,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('demand.demand_published'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('demand.publish_failed'.tr(args: ['$e'])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: Text('demand.publish_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'demand.ai_match_hint'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionLabel('demand.basic_info'.tr()),
              const SizedBox(height: 10),
              _buildFormCard([
                _buildTextField(
                  'demand.demand_title'.tr(),
                  'demand.demand_title_hint'.tr(),
                  Icons.title_rounded,
                  controller: _titleController,
                  required_: true,
                ),
                const Divider(color: AppColors.divider),
                _buildDropdownField(
                  'demand.product_category'.tr(),
                  'demand.select_category'.tr(),
                  Icons.category_outlined,
                  items: ['demand.cat_electronics'.tr(), 'demand.cat_hardware'.tr(), 'demand.cat_textile'.tr(), 'demand.cat_packaging'.tr(), 'demand.cat_machinery'.tr(), 'demand.cat_other'.tr()],
                  onChanged: (v) => _selectedCategory = v,
                ),
                const Divider(color: AppColors.divider),
                _buildTextField(
                  'demand.product_spec'.tr(),
                  'demand.product_spec_hint'.tr(),
                  Icons.straighten_outlined,
                  maxLines: 3,
                  controller: _specController,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionLabel('demand.purchase_params'.tr()),
              const SizedBox(height: 10),
              _buildFormCard([
                _buildTextField(
                  'demand.quantity'.tr(),
                  'demand.quantity_hint'.tr(),
                  Icons.production_quantity_limits_outlined,
                  controller: _quantityController,
                  required_: true,
                ),
                const Divider(color: AppColors.divider),
                _buildTextField(
                  'demand.budget'.tr(),
                  'demand.budget_hint'.tr(),
                  Icons.monetization_on_outlined,
                  controller: _budgetController,
                ),
                const Divider(color: AppColors.divider),
                _buildDropdownField(
                  'demand.delivery_period'.tr(),
                  'demand.select_delivery'.tr(),
                  Icons.calendar_today_outlined,
                  items: ['demand.delivery_7d'.tr(), 'demand.delivery_15d'.tr(), 'demand.delivery_30d'.tr(), 'demand.delivery_60d'.tr(), 'demand.delivery_90d'.tr()],
                  onChanged: (v) => _selectedDelivery = v,
                ),
                const Divider(color: AppColors.divider),
                _buildDropdownField(
                  'demand.trade_terms'.tr(),
                  'demand.select_trade_terms'.tr(),
                  Icons.handshake_outlined,
                  items: ['FOB', 'CIF', 'EXW', 'DDP', 'CFR'],
                  onChanged: (v) => _selectedTrade = v,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionLabel('demand.supplier_requirements'.tr()),
              const SizedBox(height: 10),
              _buildFormCard([
                _buildDropdownField(
                  'demand.supplier_region'.tr(),
                  'demand.select_region'.tr(),
                  Icons.location_on_outlined,
                  items: ['demand.region_any'.tr(), 'demand.region_guangdong'.tr(), 'demand.region_zhejiang'.tr(), 'demand.region_jiangsu'.tr(), 'demand.region_shanghai'.tr(), 'demand.region_fujian'.tr(), 'demand.region_shandong'.tr()],
                  onChanged: (v) => _selectedRegion = v,
                ),
                const Divider(color: AppColors.divider),
                _buildCheckField(
                  'demand.require_certified'.tr(),
                  _requireCertified,
                  (v) => setState(() => _requireCertified = v ?? false),
                ),
                _buildCheckField(
                  'demand.require_iso'.tr(),
                  _requireISO,
                  (v) => setState(() => _requireISO = v ?? false),
                ),
                _buildCheckField(
                  'demand.support_small_batch'.tr(),
                  _supportSmallBatch,
                  (v) => setState(() => _supportSmallBatch = v ?? false),
                ),
                _buildCheckField(
                  'demand.support_oem'.tr(),
                  _supportOEM,
                  (v) => setState(() => _supportOEM = v ?? false),
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionLabel('demand.attachments'.tr()),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('demand.file_upload'.tr())),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.lgBorder,
                    color: AppColors.cardBg,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: AppColors.textPlaceholder,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'demand.click_upload'.tr(),
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'demand.supported_formats'.tr(),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'demand.submit_demand'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) =>
      Text(text, style: AppTextStyles.headingS);

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextEditingController? controller,
    bool required_ = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: required_
          ? (v) => (v == null || v.trim().isEmpty)
                ? 'demand.field_required'.tr(args: [label])
                : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String hint,
    IconData icon, {
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              hint: Text(
                hint,
                style: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 14,
                ),
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckField(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label, style: AppTextStyles.bodyM),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
