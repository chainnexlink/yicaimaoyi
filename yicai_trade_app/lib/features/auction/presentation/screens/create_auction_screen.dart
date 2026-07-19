import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/auction_provider.dart';

/// 发起反向竞价 - 匹配网站 auction-create.html 4卡片布局
class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  // 产品信息
  final _titleCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _category = '';
  String _unit = '';

  // 竞价设置
  final _startingPriceCtrl = TextEditingController();
  final _minDecrementCtrl = TextEditingController(text: '1.00');
  DateTime? _signupStartTime;
  DateTime? _signupEndTime;
  DateTime? _startTime;
  DateTime? _endTime;

  // 反拍规则
  final _minParticipantsCtrl = TextEditingController(text: '3');
  final _extensionTriggerCtrl = TextEditingController(text: '5');
  final _extensionMinutesCtrl = TextEditingController(text: '5');
  final _maxExtensionsCtrl = TextEditingController(text: '10');
  bool _showRanking = true;
  bool _showLowestPrice = true;

  // 交货信息
  final _deliveryAddressCtrl = TextEditingController();
  final _deliveryDateCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  List<String> get _categories => [
    'auction.category_daily'.tr(),
    'auction.category_electronics'.tr(),
    'auction.category_textile'.tr(),
    'auction.category_food'.tr(),
    'auction.category_machinery'.tr(),
    'auction.category_building'.tr(),
    'auction.category_office'.tr(),
    'auction.category_other'.tr(),
  ];

  List<String> get _units => [
    'auction.unit_piece'.tr(),
    'auction.unit_item'.tr(),
    'auction.unit_set'.tr(),
    'auction.unit_box'.tr(),
    'auction.unit_ton'.tr(),
    'auction.unit_kg'.tr(),
    'auction.unit_meter'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _unit = 'auction.unit_piece'.tr();
    // 默认时间
    final now = DateTime.now();
    _signupStartTime = now.add(const Duration(minutes: 30));
    _signupEndTime = now.add(const Duration(hours: 1));
    _startTime = now.add(const Duration(hours: 1));
    _endTime = now.add(const Duration(hours: 25));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _specCtrl.dispose();
    _quantityCtrl.dispose();
    _startingPriceCtrl.dispose();
    _minDecrementCtrl.dispose();
    _minParticipantsCtrl.dispose();
    _extensionTriggerCtrl.dispose();
    _extensionMinutesCtrl.dispose();
    _maxExtensionsCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: _dateTimeTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
      builder: _dateTimeTheme,
    );
    if (time == null || !mounted) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Widget _dateTimeTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.cardBg,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(createAuctionProvider.notifier);
    notifier.updateField(
      title: _titleCtrl.text.trim(),
      productName: _titleCtrl.text.trim(),
      productCategory: _category,
      specification: _specCtrl.text.trim(),
      quantity: _quantityCtrl.text.trim(),
      unit: _unit,
      startingPrice: double.tryParse(_startingPriceCtrl.text.trim()),
      targetPrice: double.tryParse(_startingPriceCtrl.text.trim()),
      minDecrement: double.tryParse(_minDecrementCtrl.text.trim()),
      signupStartTime: _signupStartTime,
      signupEndTime: _signupEndTime,
      startTime: _startTime,
      endTime: _endTime,
      minParticipants: int.tryParse(_minParticipantsCtrl.text) ?? 3,
      showRanking: _showRanking,
      showLowestPrice: _showLowestPrice,
      deliveryAddress: _deliveryAddressCtrl.text.trim(),
      requiredDeliveryDate: _deliveryDateCtrl.text.trim(),
      paymentTerms: _paymentTermsCtrl.text.trim(),
      remark: _remarkCtrl.text.trim(),
      description: _specCtrl.text.trim(),
    );
    final auction = await notifier.submit();
    if (auction != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auction.auction_created'.tr())));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createAuctionProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('auction.create_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 顶部提示
            _buildHeaderBanner(),
            const SizedBox(height: 16),

            // Card 1: 产品信息
            _buildFormCard(
              title: 'auction.product_info'.tr(),
              children: [
                _buildInput(
                  controller: _titleCtrl,
                  label: 'auction.product_name_label'.tr(),
                  hint: 'auction.hint_product_name'.tr(),
                  required: true,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'auction.product_name_required'.tr()
                      : null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'auction.product_category_label'.tr(),
                  value: _category.isEmpty ? null : _category,
                  items: _categories,
                  onChanged: (v) => setState(() => _category = v ?? ''),
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _specCtrl,
                  label: 'auction.spec_label'.tr(),
                  hint: 'auction.spec_hint'.tr(),
                  required: true,
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'auction.spec_required'.tr()
                      : null,
                ),
                _buildHint('auction.spec_tip'.tr()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _quantityCtrl,
                        label: 'auction.quantity_label'.tr(),
                        hint: 'auction.hint_quantity'.tr(),
                        required: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'auction.quantity_required'.tr()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'auction.unit_label'.tr(),
                        value: _unit,
                        items: _units,
                        onChanged: (v) => setState(
                          () => _unit = v ?? 'auction.unit_piece'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 2: 竞价设置
            _buildFormCard(
              title: 'auction.auction_settings'.tr(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _startingPriceCtrl,
                        label: 'auction.starting_price'.tr(),
                        hint: 'auction.hint_price'.tr(),
                        required: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'auction.starting_price_required'.tr();
                          }
                          if (double.tryParse(v) == null) {
                            return 'auction.invalid_number'.tr();
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        controller: _minDecrementCtrl,
                        label: 'auction.min_decrement_label'.tr(),
                        hint: '1.00',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildHint('auction.price_rule_tip'.tr()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeTile(
                        label: 'auction.signup_start'.tr(),
                        value: _signupStartTime,
                        onTap: () => _pickDateTime(_signupStartTime, (dt) {
                          setState(() => _signupStartTime = dt);
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTimeTile(
                        label: 'auction.signup_end'.tr(),
                        value: _signupEndTime,
                        onTap: () => _pickDateTime(_signupEndTime, (dt) {
                          setState(() => _signupEndTime = dt);
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeTile(
                        label: 'auction.bid_start_time'.tr(),
                        value: _startTime,
                        required: true,
                        onTap: () => _pickDateTime(_startTime, (dt) {
                          setState(() => _startTime = dt);
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTimeTile(
                        label: 'auction.bid_end_time'.tr(),
                        value: _endTime,
                        required: true,
                        onTap: () => _pickDateTime(_endTime, (dt) {
                          setState(() => _endTime = dt);
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 3: 反拍规则
            _buildFormCard(
              title: 'auction.auction_rules'.tr(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _minParticipantsCtrl,
                        label: 'auction.min_participants'.tr(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        controller: _extensionTriggerCtrl,
                        label: 'auction.extension_trigger'.tr(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                _buildHint('auction.rule_tip'.tr()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _extensionMinutesCtrl,
                        label: 'auction.extension_minutes'.tr(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        controller: _maxExtensionsCtrl,
                        label: 'auction.max_extensions'.tr(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSwitchRow(
                  label: 'auction.show_ranking'.tr(),
                  value: _showRanking,
                  onChanged: (v) => setState(() => _showRanking = v),
                ),
                const SizedBox(height: 8),
                _buildSwitchRow(
                  label: 'auction.show_lowest'.tr(),
                  value: _showLowestPrice,
                  onChanged: (v) => setState(() => _showLowestPrice = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 4: 交货信息
            _buildFormCard(
              title: 'auction.delivery_info'.tr(),
              children: [
                _buildInput(
                  controller: _deliveryAddressCtrl,
                  label: 'auction.delivery_address_label'.tr(),
                  hint: 'auction.hint_address'.tr(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _deliveryDateCtrl,
                        label: 'auction.delivery_date'.tr(),
                        hint: 'auction.hint_date'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        controller: _paymentTermsCtrl,
                        label: 'auction.payment_terms_label'.tr(),
                        hint: 'auction.hint_payment_terms'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _remarkCtrl,
                  label: 'auction.other_remark'.tr(),
                  hint: 'auction.hint_remarks'.tr(),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 押金区域
            _buildDepositCard(),
            const SizedBox(height: 16),

            // 显示错误
            if (createState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  createState.error!,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'auction.save_draft'.tr(),
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: createState.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: createState.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'auction.publish_auction'.tr(),
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============ 组件工具 ============

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel_rounded, color: AppColors.featureYellow, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auction.create_title'.tr(),
                  style: AppTextStyles.headingS.copyWith(
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'auction.create_desc'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(title, style: AppTextStyles.headingM),
          ),
          // Card 内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        labelStyle: AppTextStyles.bodyS.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyS.copyWith(
          color: AppColors.textPlaceholder,
        ),
        filled: true,
        fillColor: AppColors.darkInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              '${'common.select'.tr()}$label',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ),
          ...items.map((c) => DropdownMenuItem(value: c, child: Text(c))),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyS.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        dropdownColor: AppColors.cardBg,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkInputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(required ? '$label *' : label, style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value != null
                        ? _formatDt(value)
                        : 'auction.click_select'.tr(),
                    style: AppTextStyles.bodyS.copyWith(
                      color: value != null
                          ? AppColors.textTitle
                          : AppColors.textPlaceholder,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyM),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textSecondary,
          inactiveTrackColor: AppColors.border,
        ),
      ],
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
      ),
    );
  }

  Widget _buildDepositCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  'auction.publish_deposit'.tr(),
                  style: AppTextStyles.headingM,
                ),
                const SizedBox(width: 8),
                Text(
                  'auction.deposit_required'.tr(),
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: AppRadius.smBorder,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyL,
                          children: [
                            TextSpan(
                              text: 'auction.publish_deposit_label'.tr(),
                            ),
                            TextSpan(
                              text: '\$50.00',
                              style: AppTextStyles.bodyL.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' USD'),
                          ],
                        ),
                      ),
                      Text(
                        'common.not_paid'.tr(),
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auction.deposit_refund_note'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('auction.deposit_coming'.tr()),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'auction.pay_deposit'.tr(),
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('auction.voucher_coming'.tr()),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.catPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'auction.use_voucher'.tr(),
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDt(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
