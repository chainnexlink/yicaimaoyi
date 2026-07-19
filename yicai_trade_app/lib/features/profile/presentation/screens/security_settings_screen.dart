import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';

/// Security settings screen
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text('security.title'.tr(), style: AppTextStyles.headingM),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSecurityCard([
            _buildSecurityItem(
              'security.change_password'.tr(),
              'security.change_password_tip'.tr(),
              Icons.lock_outline_rounded,
              AppColors.primary,
              () => _showChangePasswordDialog(),
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 56),
            _buildSecurityItem(
              'security.bind_phone'.tr(),
              '${'security.bound'.tr()}: 138****8888',
              Icons.phone_android_outlined,
              AppColors.success,
              () {},
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 56),
            _buildSecurityItem(
              'security.bind_email'.tr(),
              'security.not_bound'.tr(),
              Icons.email_outlined,
              AppColors.warning,
              () {},
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 56),
            _buildSecurityItem(
              'security.wechat_binding'.tr(),
              'security.not_bound'.tr(),
              Icons.wechat_outlined,
              AppColors.success,
              () {},
            ),
          ]),
          const SizedBox(height: 16),
          _buildSecurityCard([
            _buildSecurityItem(
              'security.device_management'.tr(),
              'security.view_devices'.tr(),
              Icons.devices_outlined,
              AppColors.catBlue,
              () {},
            ),
            const Divider(height: 0.5, color: AppColors.divider, indent: 56),
            _buildSecurityItem(
              'security.login_history'.tr(),
              'security.view_login_history'.tr(),
              Icons.history_outlined,
              AppColors.catPurple,
              () {},
            ),
          ]),
          const SizedBox(height: 16),
          _buildSecurityCard([
            _buildSecurityItem(
              'security.delete_account'.tr(),
              'security.delete_account_desc'.tr(),
              Icons.delete_forever_outlined,
              AppColors.error,
              () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSecurityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyL.copyWith(color: AppColors.textTitle),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textPlaceholder,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showChangePasswordDialog() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          'security.change_password'.tr(),
          style: AppTextStyles.headingS,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField('security.old_password'.tr(), oldPwdCtrl),
            const SizedBox(height: 12),
            _buildPasswordField('security.new_password'.tr(), newPwdCtrl),
            const SizedBox(height: 12),
            _buildPasswordField(
              'security.confirm_password'.tr(),
              confirmPwdCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              oldPwdCtrl.dispose();
              newPwdCtrl.dispose();
              confirmPwdCtrl.dispose();
            },
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              oldPwdCtrl.dispose();
              newPwdCtrl.dispose();
              confirmPwdCtrl.dispose();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('security.password_changed'.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
