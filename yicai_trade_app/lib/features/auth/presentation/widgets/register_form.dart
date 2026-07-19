import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/cyan_button.dart';
import '../../presentation/providers/auth_provider.dart';

/// 注册表单组件
class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;
  String? _errorMessage;
  String _selectedRole = 'BUYER';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      setState(() => _errorMessage = 'auth.agree_terms_required'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isNewUser = await ref
          .read(authProvider.notifier)
          .register(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
            userType: _selectedRole,
          );

      if (mounted) {
        // 新用户跳转引导页，老用户直接进首页
        if (isNewUser) {
          context.go(RouteNames.onboarding);
        } else {
          context.go(RouteNames.home);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 错误提示
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentRed.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 角色选择
          Row(
            children: [
              Expanded(
                child: _RoleChip(
                  label: 'auth.role_buyer'.tr(),
                  icon: Icons.shopping_cart_outlined,
                  isSelected: _selectedRole == 'BUYER',
                  onTap: () => setState(() => _selectedRole = 'BUYER'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleChip(
                  label: 'auth.role_supplier'.tr(),
                  icon: Icons.factory_outlined,
                  isSelected: _selectedRole == 'SUPPLIER',
                  onTap: () => setState(() => _selectedRole = 'SUPPLIER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 用户名
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.textMuted,
              ),
              hintText: 'auth.register_username'.tr(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'auth.register_username'.tr()
                : null,
          ),
          const SizedBox(height: 14),

          // 邮箱
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.textMuted,
              ),
              hintText: 'auth.register_email'.tr(),
            ),
          ),
          const SizedBox(height: 14),

          // 密码
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.textMuted,
              ),
              hintText: 'auth.register_password'.tr(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'auth.register_password'.tr();
              if (v.length < 6) return 'auth.password_min_length'.tr();
              return null;
            },
          ),
          const SizedBox(height: 14),

          // 确认密码
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.textMuted,
              ),
              hintText: 'auth.register_confirm'.tr(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'auth.password_mismatch'.tr();
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 同意条款
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  activeColor: AppColors.primaryCyan,
                  side: const BorderSide(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      'auth.register_agree'.tr(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.termsOfService),
                      child: Text(
                        'auth.terms_of_service'.tr(),
                        style: const TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 注册按钮
          CyanButton(
            text: 'auth.register_submit'.tr(),
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleRegister,
          ),
        ],
      ),
    );
  }
}

/// 角色选择 Chip
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryCyanAlpha10 : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primaryCyan : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primaryCyan
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
