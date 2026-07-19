import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/supplier_center_provider.dart';

/// 供应商产品编辑/添加 - 对应网站 supplier-product-edit.html
class SupplierProductEditScreen extends ConsumerStatefulWidget {
  final int? productId;
  const SupplierProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<SupplierProductEditScreen> createState() =>
      _SupplierProductEditScreenState();
}

class _SupplierProductEditScreenState
    extends ConsumerState<SupplierProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _moqCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final repo = ref.read(supplierCenterRepositoryProvider);
      final result = await repo.getProducts();
      final product = result.content
          .where((p) => p.id == widget.productId)
          .firstOrNull;
      if (product != null && mounted) {
        setState(() {
          _nameCtrl.text = product.name;
          _categoryCtrl.text = product.category ?? '';
          _priceCtrl.text = product.price?.toString() ?? '';
          _moqCtrl.text = product.minOrderQty?.toString() ?? '';
          _unitCtrl.text = product.unit ?? '';
          _descCtrl.text = product.description ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _moqCtrl.dispose();
    _unitCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text(
          _isEdit
              ? 'supplier_center.edit_product'.tr()
              : 'supplier_center.add_product_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('supplier_center.basic_info'.tr(), [
              _buildTextField(
                'supplier_center.product_name_label'.tr(),
                _nameCtrl,
                required: true,
              ),
              _buildTextField(
                'supplier_center.product_category_label'.tr(),
                _categoryCtrl,
              ),
              _buildTextField(
                'supplier_center.description'.tr(),
                _descCtrl,
                maxLines: 4,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('supplier_center.price_info'.tr(), [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'supplier_center.unit_price'.tr(),
                      _priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      'supplier_center.unit_label'.tr(),
                      _unitCtrl,
                      hint: 'supplier_center.unit_hint'.tr(),
                    ),
                  ),
                ],
              ),
              _buildTextField(
                'supplier_center.min_order_qty'.tr(),
                _moqCtrl,
                keyboardType: TextInputType.number,
              ),
            ]),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingS.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
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
          hintText: hint,
          labelStyle: AppTextStyles.bodyS.copyWith(
            color: AppColors.textSecondary,
          ),
          hintStyle: AppTextStyles.bodyS.copyWith(
            color: AppColors.textPlaceholder,
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
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '${'common.input'.tr()}$label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'supplier_center.product_images'.tr(),
            style: AppTextStyles.headingS.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // 集成 image_picker 上传产品图片（待实现）
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.searchBarBg,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textPlaceholder,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'supplier_center.upload_images'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textOnPrimary,
                ),
              )
            : Text(
                _isEdit
                    ? 'supplier_center.save_changes'.tr()
                    : 'supplier_center.publish_product'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text),
      'minOrderQty': double.tryParse(_moqCtrl.text),
      'unit': _unitCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    };

    try {
      final repo = ref.read(supplierCenterRepositoryProvider);
      if (_isEdit) {
        await repo.updateProduct(widget.productId!, data);
      } else {
        await repo.createProduct(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'supplier_center.product_updated'.tr()
                  : 'supplier_center.product_published'.tr(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'common.operation_failed'.tr()}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
