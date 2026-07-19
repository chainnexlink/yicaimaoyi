import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_shadows.dart';

/// 监控设置页面 - 对应网站 monitor-settings.html
class MonitorSettingsScreen extends ConsumerStatefulWidget {
  const MonitorSettingsScreen({super.key});

  @override
  ConsumerState<MonitorSettingsScreen> createState() =>
      _MonitorSettingsScreenState();
}

class _MonitorSettingsScreenState extends ConsumerState<MonitorSettingsScreen> {
  bool _enableAlerts = true;
  bool _emailNotify = true;
  bool _smsNotify = false;
  bool _pushNotify = true;
  String _frequency = 'DAILY';
  double _delayThreshold = 3;
  double _qualityThreshold = 90;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'supplier_center.monitor_settings_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'common.save'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard('supplier_center.alert_switch'.tr(), [
            _buildSwitchTile(
              'supplier_center.enable_alert'.tr(),
              'supplier_center.enable_alert_desc'.tr(),
              Icons.notification_important_outlined,
              _enableAlerts,
              (v) => setState(() => _enableAlerts = v),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('supplier_center.notification_method'.tr(), [
            _buildSwitchTile(
              'supplier_center.email_notify'.tr(),
              'supplier_center.email_notify_desc'.tr(),
              Icons.email_outlined,
              _emailNotify,
              (v) => setState(() => _emailNotify = v),
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 56),
            _buildSwitchTile(
              'supplier_center.sms_notify'.tr(),
              'supplier_center.sms_notify_desc'.tr(),
              Icons.sms_outlined,
              _smsNotify,
              (v) => setState(() => _smsNotify = v),
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 56),
            _buildSwitchTile(
              'supplier_center.push_notify'.tr(),
              'supplier_center.push_notify_desc'.tr(),
              Icons.notifications_outlined,
              _pushNotify,
              (v) => setState(() => _pushNotify = v),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('supplier_center.monitor_frequency'.tr(), [
            _buildFrequencySelector(),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('supplier_center.alert_threshold'.tr(), [
            _buildSliderTile(
              'supplier_center.delivery_delay_alert'.tr(),
              '${'supplier_center.delay_days'.tr()} ${_delayThreshold.toInt()} ${'supplier_center.delay_days_unit'.tr()}',
              Icons.schedule_outlined,
              _delayThreshold,
              1,
              14,
              13,
              (v) => setState(() => _delayThreshold = v),
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 16),
            _buildSliderTile(
              'supplier_center.quality_alert'.tr(),
              '${'supplier_center.quality_below'.tr()} ${_qualityThreshold.toInt()}% ${'supplier_center.quality_below_unit'.tr()}',
              Icons.verified_outlined,
              _qualityThreshold,
              50,
              100,
              10,
              (v) => setState(() => _qualityThreshold = v),
            ),
          ]),
          const SizedBox(height: 40),
        ],
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(fontSize: 11),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        activeThumbColor: AppColors.textOnPrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildFrequencySelector() {
    final options = [
      ('REALTIME', 'supplier_center.freq_realtime'.tr()),
      ('HOURLY', 'supplier_center.freq_hourly'.tr()),
      ('DAILY', 'supplier_center.freq_daily'.tr()),
      ('WEEKLY', 'supplier_center.freq_weekly'.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: options.map((o) {
          final isSelected = _frequency == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _frequency = o.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : AppColors.searchBarBg,
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.textTitle,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primaryAlpha20,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('supplier_center.settings_saved'.tr()),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }
}
