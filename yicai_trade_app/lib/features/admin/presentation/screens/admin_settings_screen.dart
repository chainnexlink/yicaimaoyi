import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';

/// 系统设置页面 - 管理后台系统配置
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // 平台基础设置
  bool _enableRegistration = true;
  bool _enableAuction = true;
  bool _enableSmartMatch = true;
  bool _enableMonitor = true;
  bool _maintenanceMode = false;

  // 通知设置
  bool _emailNotify = true;
  bool _smsNotify = false;
  bool _pushNotify = true;

  // 交易设置
  double _platformFeeRate = 2.0;
  int _orderTimeoutHours = 48;
  int _paymentTimeoutHours = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('admin.settings_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ====== 平台功能开关 ======
          _buildSectionTitle(
            'admin.platform_features'.tr(),
            Icons.toggle_on_outlined,
          ),
          const SizedBox(height: 10),
          _buildSettingCard([
            _buildSwitchItem(
              'admin.open_registration'.tr(),
              'admin.open_registration_desc'.tr(),
              Icons.person_add_outlined,
              AppColors.primary,
              _enableRegistration,
              (v) => setState(() => _enableRegistration = v),
            ),
            _buildDivider(),
            _buildSwitchItem(
              'admin.auction_feature'.tr(),
              'admin.auction_feature_desc'.tr(),
              Icons.gavel_rounded,
              AppColors.featureYellow,
              _enableAuction,
              (v) => setState(() => _enableAuction = v),
            ),
            _buildDivider(),
            _buildSwitchItem(
              'admin.smart_match_feature'.tr(),
              'admin.smart_match_feature_desc'.tr(),
              Icons.auto_awesome_outlined,
              AppColors.catPurple,
              _enableSmartMatch,
              (v) => setState(() => _enableSmartMatch = v),
            ),
            _buildDivider(),
            _buildSwitchItem(
              'admin.production_monitor'.tr(),
              'admin.production_monitor_desc'.tr(),
              Icons.monitor_heart_outlined,
              AppColors.featureTeal,
              _enableMonitor,
              (v) => setState(() => _enableMonitor = v),
            ),
            _buildDivider(),
            _buildSwitchItem(
              'admin.maintenance_mode'.tr(),
              'admin.maintenance_mode_desc'.tr(),
              Icons.construction_rounded,
              AppColors.error,
              _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v),
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 24),

          // ====== 交易设置 ======
          _buildSectionTitle(
            'admin.trade_rules'.tr(),
            Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 10),
          _buildSettingCard([
            _buildSliderItem(
              'admin.service_fee_rate'.tr(),
              '${'common.current'.tr()}: ${_platformFeeRate.toStringAsFixed(1)}%',
              Icons.percent_rounded,
              AppColors.secondary,
              _platformFeeRate,
              0.0,
              10.0,
              (v) => setState(() => _platformFeeRate = v),
            ),
            _buildDivider(),
            _buildNumberItem(
              'admin.order_timeout'.tr(),
              'admin.order_timeout_desc'.tr(),
              Icons.timer_outlined,
              AppColors.warning,
              _orderTimeoutHours,
              (v) => setState(() => _orderTimeoutHours = v),
            ),
            _buildDivider(),
            _buildNumberItem(
              'admin.payment_timeout'.tr(),
              'admin.payment_timeout_desc'.tr(),
              Icons.payment_outlined,
              AppColors.catBlue,
              _paymentTimeoutHours,
              (v) => setState(() => _paymentTimeoutHours = v),
            ),
          ]),

          const SizedBox(height: 24),

          // ====== 通知设置 ======
          _buildSectionTitle(
            'admin.push_notification'.tr(),
            Icons.notifications_outlined,
          ),
          const SizedBox(height: 10),
          _buildSettingCard([
            _buildSwitchItem(
              'admin.email_notification'.tr(),
              'admin.email_notification_desc'.tr(),
              Icons.email_outlined,
              AppColors.catBlue,
              _emailNotify,
              (v) => setState(() => _emailNotify = v),
            ),
            _buildDivider(),
            _buildSwitchItem(
              'admin.sms_notification'.tr(),
              'admin.sms_notification_desc'.tr(),
              Icons.sms_outlined,
              AppColors.catGreen,
              _smsNotify,
              (v) => setState(() => _smsNotify = v),
            ),
            _buildDivider(),
            _buildSwitchItem(
              'admin.app_push'.tr(),
              'admin.app_push_desc'.tr(),
              Icons.notifications_active_outlined,
              AppColors.catOrange,
              _pushNotify,
              (v) => setState(() => _pushNotify = v),
            ),
          ]),

          const SizedBox(height: 24),

          // ====== 系统信息 ======
          _buildSectionTitle(
            'admin.system_info'.tr(),
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildSettingCard([
            _buildInfoItem(
              'admin.platform_version'.tr(),
              'v2.0.0',
              Icons.verified_outlined,
              AppColors.primary,
            ),
            _buildDivider(),
            _buildInfoItem(
              'admin.api_version'.tr(),
              'v1.0',
              Icons.api_rounded,
              AppColors.catBlue,
            ),
            _buildDivider(),
            _buildInfoItem(
              'admin.db_status'.tr(),
              'admin.running_normal'.tr(),
              Icons.storage_outlined,
              AppColors.success,
            ),
            _buildDivider(),
            _buildInfoItem(
              'admin.cache_status'.tr(),
              '128MB / 512MB',
              Icons.cached_rounded,
              AppColors.catOrange,
            ),
          ]),

          const SizedBox(height: 24),

          // ====== 危险操作 ======
          _buildSectionTitle(
            'admin.danger_zone'.tr(),
            Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 10),
          _buildSettingCard([
            _buildActionItem(
              'admin.clear_cache'.tr(),
              'admin.clear_cache_desc'.tr(),
              Icons.delete_sweep_outlined,
              AppColors.warning,
              () => _showConfirmDialog(
                'admin.clear_cache_confirm'.tr(),
                'admin.clear_cache_warning'.tr(),
              ),
            ),
            _buildDivider(),
            _buildActionItem(
              'admin.rebuild_index'.tr(),
              'admin.rebuild_index_desc'.tr(),
              Icons.manage_search_rounded,
              AppColors.catPurple,
              () => _showConfirmDialog(
                'admin.rebuild_index_confirm'.tr(),
                'admin.rebuild_index_warning'.tr(),
              ),
            ),
            _buildDivider(),
            _buildActionItem(
              'admin.export_data'.tr(),
              'admin.export_data_desc'.tr(),
              Icons.download_outlined,
              AppColors.catBlue,
              () => _showSnack('admin.export_submitted'.tr()),
            ),
          ]),

          const SizedBox(height: 32),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
                elevation: 0,
              ),
              child: Text(
                'admin.save_settings'.tr(),
                style: const TextStyle(
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

  // ============ 构建器 ============

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headingS.copyWith(fontSize: 15)),
      ],
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      indent: 56,
      endIndent: 16,
      color: AppColors.borderSubtle,
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyM.copyWith(
                    color: isDestructive
                        ? AppColors.error
                        : AppColors.textTitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDestructive
                ? AppColors.error
                : AppColors.primary,
            activeTrackColor:
                (isDestructive ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textPlaceholder,
            inactiveTrackColor: AppColors.borderSubtle,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.textTitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * 10).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textTitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          // 数值调节器
          Container(
            decoration: BoxDecoration(
              color: AppColors.searchBarBg,
              borderRadius: AppRadius.pillBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: value > 1 ? () => onChanged(value - 1) : null,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onChanged(value + 1),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textTitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textTitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(subtitle, style: AppTextStyles.caption),
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
      ),
    );
  }

  // ============ 操作 ============

  void _saveSettings() {
    _showSnack('admin.settings_saved'.tr());
  }

  void _showConfirmDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(title, style: AppTextStyles.headingS),
        content: Text(
          message,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('admin.action_submitted'.tr());
            },
            child: Text(
              'common.confirm'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.cardBgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      );
    }
  }
}
