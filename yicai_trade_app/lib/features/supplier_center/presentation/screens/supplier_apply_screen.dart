import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/supplier_center_provider.dart';

/// 供应商入驻申请 - 对应网站 supplier-apply.html
class SupplierApplyScreen extends ConsumerStatefulWidget {
  const SupplierApplyScreen({super.key});

  @override
  ConsumerState<SupplierApplyScreen> createState() =>
      _SupplierApplyScreenState();
}

class _SupplierApplyScreenState extends ConsumerState<SupplierApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: 企业基本信息
  final _companyNameCtrl = TextEditingController();
  final _legalPersonCtrl = TextEditingController();
  final _businessLicenseCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Step 2: 联系信息
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();

  // Step 3: 经营信息
  final _mainProductsCtrl = TextEditingController();
  final _factoryAreaCtrl = TextEditingController();
  final _employeeCountCtrl = TextEditingController();
  final _annualRevenueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supplierApplyProvider.notifier).checkStatus();
    });
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _legalPersonCtrl.dispose();
    _businessLicenseCtrl.dispose();
    _addressCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _mainProductsCtrl.dispose();
    _factoryAreaCtrl.dispose();
    _employeeCountCtrl.dispose();
    _annualRevenueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applyState = ref.watch(supplierApplyProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(
          'supplier_center.apply_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(applyState),
    );
  }

  Widget _buildBody(SupplierApplyState applyState) {
    // 已提交 - 显示审核状态
    if (applyState.applicationStatus == 'PENDING') {
      return _buildStatusView(
        'supplier_center.apply_reviewing'.tr(),
        'supplier_center.apply_reviewing_desc'.tr(),
        Icons.hourglass_top_rounded,
        AppColors.warning,
      );
    }
    if (applyState.applicationStatus == 'APPROVED') {
      return _buildStatusView(
        'supplier_center.apply_approved'.tr(),
        'supplier_center.apply_approved_desc'.tr(),
        Icons.check_circle_outline,
        AppColors.success,
      );
    }
    if (applyState.applicationStatus == 'REJECTED') {
      return _buildStatusView(
        'supplier_center.apply_rejected'.tr(),
        'supplier_center.apply_rejected_desc'.tr(),
        Icons.cancel_outlined,
        AppColors.error,
      );
    }
    if (applyState.submitSuccess) {
      return _buildStatusView(
        'supplier_center.apply_submitted'.tr(),
        'supplier_center.apply_submitted_desc'.tr(),
        Icons.mark_email_read_outlined,
        AppColors.primary,
      );
    }

    // 填写表单
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_currentStep == 0) _buildStep1(),
                if (_currentStep == 1) _buildStep2(),
                if (_currentStep == 2) _buildStep3(),
                const SizedBox(height: 24),
                _buildNavigationButtons(applyState),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusView(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.headingL.copyWith(color: color)),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'supplier_center.company_info'.tr(),
      'supplier_center.contact_info'.tr(),
      'supplier_center.business_info'.tr(),
    ];
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= _currentStep
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.searchBarBg,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 3,
                              )
                            : null,
                      ),
                      child: Center(
                        child: i < _currentStep
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.textOnPrimary,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? AppColors.textOnPrimary
                                      : AppColors.textPlaceholder,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textPlaceholder,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1 && i >= 1) const SizedBox(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return _buildFormSection('supplier_center.company_basic_info'.tr(), [
      _buildField(
        'supplier_center.company_name'.tr(),
        _companyNameCtrl,
        required: true,
      ),
      _buildField(
        'supplier_center.legal_rep'.tr(),
        _legalPersonCtrl,
        required: true,
      ),
      _buildField(
        'supplier_center.business_license_no'.tr(),
        _businessLicenseCtrl,
        required: true,
      ),
      _buildField(
        'supplier_center.company_address'.tr(),
        _addressCtrl,
        required: true,
      ),
      _buildUploadArea('supplier_center.business_license_scan'.tr()),
    ]);
  }

  Widget _buildStep2() {
    return _buildFormSection('supplier_center.contact_info'.tr(), [
      _buildField(
        'supplier_center.contact_name'.tr(),
        _contactNameCtrl,
        required: true,
      ),
      _buildField(
        'supplier_center.contact_phone'.tr(),
        _contactPhoneCtrl,
        required: true,
        keyboardType: TextInputType.phone,
      ),
      _buildField(
        'supplier_center.contact_email'.tr(),
        _contactEmailCtrl,
        keyboardType: TextInputType.emailAddress,
      ),
    ]);
  }

  Widget _buildStep3() {
    return _buildFormSection('supplier_center.business_info'.tr(), [
      _buildField(
        'supplier_center.main_products'.tr(),
        _mainProductsCtrl,
        required: true,
        maxLines: 3,
      ),
      _buildField(
        'supplier_center.factory_area'.tr(),
        _factoryAreaCtrl,
        keyboardType: TextInputType.number,
      ),
      _buildField(
        'supplier_center.employee_count'.tr(),
        _employeeCountCtrl,
        keyboardType: TextInputType.number,
      ),
      _buildField(
        'supplier_center.annual_revenue'.tr(),
        _annualRevenueCtrl,
        keyboardType: TextInputType.number,
      ),
      _buildUploadArea('supplier_center.qualifications'.tr()),
    ]);
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingS.copyWith(fontSize: 15)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyS.copyWith(
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.searchBarBg,
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdBorder,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdBorder,
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '${'common.input'.tr()}$label' : null
            : null,
      ),
    );
  }

  Widget _buildUploadArea(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.searchBarBg,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.textPlaceholder,
                  size: 30,
                ),
                const SizedBox(height: 6),
                Text(
                  '${'common.upload'.tr()}$label',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(SupplierApplyState applyState) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('common.previous_step'.tr(), style: TextStyle(fontSize: 15)),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: applyState.isSubmitting ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: applyState.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Text(
                    _currentStep < 2
                        ? 'common.next_step'.tr()
                        : 'supplier_center.submit_apply'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      if (!_formKey.currentState!.validate()) return;
      ref.read(supplierApplyProvider.notifier).submitApplication({
        'companyName': _companyNameCtrl.text.trim(),
        'legalPerson': _legalPersonCtrl.text.trim(),
        'businessLicense': _businessLicenseCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'contactName': _contactNameCtrl.text.trim(),
        'contactPhone': _contactPhoneCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'mainProducts': _mainProductsCtrl.text.trim(),
        'factoryArea': _factoryAreaCtrl.text.trim(),
        'employeeCount': _employeeCountCtrl.text.trim(),
        'annualRevenue': _annualRevenueCtrl.text.trim(),
      });
    }
  }
}
