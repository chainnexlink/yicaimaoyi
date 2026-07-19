import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/constants/app_constants.dart';

/// 设置页面 - V2 主题重新设计
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('settings.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 语言和通知设置
          _buildSettingsGroup([
            _SettingItem(
              icon: Icons.language_rounded,
              color: AppColors.primary,
              title: 'settings.language'.tr(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocales.getLocaleName(context.locale),
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textPlaceholder,
                    size: 20,
                  ),
                ],
              ),
              onTap: () => _showLanguageDialog(context),
            ),
            _SettingItem(
              icon: Icons.notifications_none_rounded,
              color: AppColors.featureYellow,
              title: 'settings.notification'.tr(),
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('settings.notification_coming_soon'.tr()))),
            ),
          ]),
          const SizedBox(height: 12),

          // 其他设置
          _buildSettingsGroup([
            _SettingItem(
              icon: Icons.cleaning_services_outlined,
              color: AppColors.featureTeal,
              title: 'settings.cache'.tr(),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('settings.clear_cache'.tr()),
                    content: Text('settings.clear_cache_confirm'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('common.cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('settings.cache_cleared'.tr())),
                          );
                        },
                        child: Text('common.confirm'.tr()),
                      ),
                    ],
                  ),
                );
              },
            ),
            _SettingItem(
              icon: Icons.feedback_outlined,
              color: AppColors.secondary,
              title: 'settings.feedback'.tr(),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: Text('settings.feedback'.tr()),
                      content: TextField(
                        controller: controller,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'settings.feedback_hint'.tr(),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('common.cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('settings.feedback_thanks'.tr())),
                            );
                          },
                          child: Text('common.submit'.tr()),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            _SettingItem(
              icon: Icons.info_outline_rounded,
              color: AppColors.textSecondary,
              title: 'settings.version'.tr(),
              trailing: Text(
                'v${AppConstants.appVersion}',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: i == 0 && items.length == 1
                      ? AppRadius.lgBorder
                      : i == 0
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        )
                      : i == items.length - 1
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                      : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                item.color.withValues(alpha: 0.2),
                                item.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyL.copyWith(
                              color: AppColors.textTitle,
                            ),
                          ),
                        ),
                        item.trailing ??
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textPlaceholder,
                              size: 20,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 0.5,
                  indent: 66,
                  endIndent: 16,
                  color: AppColors.borderSubtle,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text('settings.language'.tr(), style: AppTextStyles.headingS),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocales.supportedLocales.map((locale) {
            final isSelected = ctx.locale == locale;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppLocales.changeLocale(ctx, locale);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: AppRadius.mdBorder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: AppRadius.mdBorder,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocales.getLocaleName(locale),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTitle,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingItem({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    this.onTap,
  });
}
