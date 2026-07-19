import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 供应商生产进度上传 - 对应网站 supplier-monitor-upload.html，连接实际API
class MonitorUploadScreen extends ConsumerStatefulWidget {
  const MonitorUploadScreen({super.key});

  @override
  ConsumerState<MonitorUploadScreen> createState() =>
      _MonitorUploadScreenState();
}

class _MonitorUploadScreenState extends ConsumerState<MonitorUploadScreen> {
  final _remarkCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  String _selectedStage = 'PRODUCING';
  double _progressValue = 0;
  bool _isSubmitting = false;

  // 订单选择
  Map<String, dynamic>? _selectedOrder;
  List<Map<String, dynamic>> _availableOrders = [];
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadActiveOrders);
  }

  Future<void> _loadActiveOrders() async {
    try {
      final authState = ref.read(authProvider);
      final userId = authState is AuthAuthenticated ? authState.user.id : 0;
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        ApiConstants.ordersBySupplier(userId),
        queryParameters: {'status': 'CONFIRMED', 'size': 50},
      );
      final data = response.data;
      List items = [];
      if (data is Map && data.containsKey('data')) {
        final body = data['data'];
        if (body is Map && body.containsKey('content')) {
          items = body['content'] as List;
        } else if (body is List) {
          items = body;
        }
      } else if (data is List) {
        items = data;
      }
      // 也加载生产中的订单
      final response2 = await dio.get(
        ApiConstants.ordersBySupplier(userId),
        queryParameters: {'status': 'IN_PRODUCTION', 'size': 50},
      );
      final data2 = response2.data;
      if (data2 is Map && data2.containsKey('data')) {
        final body2 = data2['data'];
        if (body2 is Map && body2.containsKey('content')) {
          items.addAll(body2['content'] as List);
        } else if (body2 is List) {
          items.addAll(body2);
        }
      }
      if (mounted) {
        setState(() {
          _availableOrders = items
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _loadingOrders = false;
          if (_availableOrders.isNotEmpty) {
            _selectedOrder = _availableOrders.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    _titleCtrl.dispose();
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
          'supplier_center.monitor_upload_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 订单选择
          _buildSectionCard('supplier_center.select_order'.tr(), [
            _buildOrderSelector(),
          ]),
          const SizedBox(height: 16),

          // 上传标题
          _buildSectionCard('supplier_center.upload_title_label'.tr(), [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _titleCtrl,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
                decoration: InputDecoration(
                  hintText: 'supplier_center.upload_title_hint'.tr(),
                  hintStyle: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: AppColors.searchBarBg,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdBorder,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 生产阶段选择
          _buildSectionCard('supplier_center.production_stage'.tr(), [
            _buildStageSelector(),
          ]),
          const SizedBox(height: 16),

          // 进度数值
          _buildSectionCard('supplier_center.completion_progress'.tr(), [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'supplier_center.current_progress'.tr(),
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.textTitle,
                        ),
                      ),
                      Text(
                        '${_progressValue.toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _progressValue >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primaryAlpha20,
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _progressValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (v) => setState(() => _progressValue = v),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressValue / 100,
                      backgroundColor: AppColors.divider,
                      color: _progressValue >= 100
                          ? AppColors.success
                          : AppColors.primary,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 图片上传
          _buildSectionCard('supplier_center.site_photos'.tr(), [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _buildImageUploadBox(),
                  const SizedBox(width: 12),
                  _buildImageUploadBox(),
                  const SizedBox(width: 12),
                  _buildImageUploadBox(),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 备注
          _buildSectionCard('supplier_center.remark_desc'.tr(), [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextFormField(
                controller: _remarkCtrl,
                maxLines: 4,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
                decoration: InputDecoration(
                  hintText: 'supplier_center.remark_hint'.tr(),
                  hintStyle: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: AppColors.searchBarBg,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdBorder,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),

          // 提交按钮
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
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
                      'supplier_center.submit_progress'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOrderSelector() {
    if (_loadingOrders) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_availableOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: AppRadius.mdBorder,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'supplier_center.no_orders_for_upload'.tr(),
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.searchBarBg,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            dropdownColor: AppColors.cardBgElevated,
            value: _selectedOrder?['id'],
            hint: Text(
              'supplier_center.select_order'.tr(),
              style: TextStyle(color: AppColors.textPlaceholder),
            ),
            items: _availableOrders.map((order) {
              return DropdownMenuItem<int>(
                value: order['id'],
                child: Text(
                  '${order['orderNo'] ?? order['id']} - ${order['productName'] ?? 'supplier_center.product'.tr()}',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textTitle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (id) {
              setState(() {
                _selectedOrder = _availableOrders.firstWhere(
                  (o) => o['id'] == id,
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: AppTextStyles.headingS.copyWith(fontSize: 14),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStageSelector() {
    final stages = [
      (
        'MATERIAL',
        'supplier_center.stage_material'.tr(),
        Icons.inventory_outlined,
      ),
      (
        'PRODUCING',
        'supplier_center.stage_production'.tr(),
        Icons.precision_manufacturing_outlined,
      ),
      ('QC', 'supplier_center.stage_inspection'.tr(), Icons.verified_outlined),
      (
        'PACKING',
        'supplier_center.stage_packaging'.tr(),
        Icons.all_inbox_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: stages.map((s) {
          final isSelected = _selectedStage == s.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedStage = s.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : AppColors.searchBarBg,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      s.$3,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPlaceholder,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageUploadBox() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('supplier_center.photo_coming'.tr()),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.searchBarBg,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.textPlaceholder,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('supplier_center.select_order_first'.tr())),
      );
      return;
    }
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('supplier_center.fill_upload_title'.tr())),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final authState = ref.read(authProvider);
      final userId = authState is AuthAuthenticated ? authState.user.id : 0;
      final userName = authState is AuthAuthenticated
          ? authState.user.displayName
          : '';
      final dio = ref.read(dioProvider);

      await dio.post(
        ApiConstants.monitors,
        data: {
          'orderId': _selectedOrder!['id'],
          'supplierId': userId,
          'buyerId': _selectedOrder!['buyerId'],
          'title': _titleCtrl.text,
          'description': _remarkCtrl.text,
          'stage': _selectedStage,
          'progressPercent': _progressValue.toInt(),
          'uploadType': 'SCHEDULED',
          'uploaderId': userId,
          'uploaderName': userName,
        },
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('supplier_center.progress_uploaded'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'supplier_center.upload_failed'.tr()}: $e'),
          ),
        );
      }
    }
  }
}
