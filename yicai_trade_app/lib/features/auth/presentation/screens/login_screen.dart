import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

/// 登录页 - 深色科技风，三 Tab（用户登录/供应商登录/注册）
/// 参考网站 login.html 完整功能
class LoginScreen extends StatefulWidget {
  final int initialTabIndex;

  const LoginScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 36),

              // Logo 区域
              _buildLogo(),
              const SizedBox(height: 32),

              // Tab 选择器
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.cardSmall,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryAlpha20,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(text: 'auth.tab_personal'.tr()),
                    Tab(text: 'auth.tab_supplier'.tr()),
                    Tab(text: 'auth.tab_register'.tr()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab 内容 - 使用 AnimatedBuilder 而非固定高度
              ListenableBuilder(
                listenable: _tabController,
                builder: (context, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_tabController.index),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: _buildTabContent(_tabController.index),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 底部切换提示
              _buildBottomHint(),

              const SizedBox(height: 16),

              // 供应商入驻推广（仅在用户登录 Tab 显示）
              ListenableBuilder(
                listenable: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 1) return const SizedBox.shrink();
                  return _buildSupplierPromoCard();
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const LoginForm(isSupplier: false);
      case 1:
        return const LoginForm(isSupplier: true);
      case 2:
        return const RegisterForm();
      default:
        return const LoginForm(isSupplier: false);
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo 图标
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.buttonPrimary,
          ),
          child: const Center(
            child: Text(
              'YC',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // 平台名称
        Text(
          'app.title'.tr(),
          style: AppTextStyles.headingL.copyWith(color: AppColors.textTitle),
        ),
        const SizedBox(height: 4),
        // 副标语
        Text(
          'app_slogan'.tr(),
          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        // 英文标语
        const Text(
          'One-Stop Sourcing for Global Buyers',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHint() {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        final isRegisterTab = _tabController.index == 2;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isRegisterTab ? 'auth.has_account'.tr() : 'auth.no_account'.tr(),
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(isRegisterTab ? 0 : 2);
              },
              child: Text(
                isRegisterTab ? 'auth.login_now'.tr() : 'auth.register_now'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 供应商入驻推广卡片 - 参考网站右侧区域
  Widget _buildSupplierPromoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryDark.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryAlpha20,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'auth.become_supplier'.tr(),
                style: const TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPromoItem('auth.promo_smart_match'.tr()),
          _buildPromoItem('auth.promo_global_buyers'.tr()),
          _buildPromoItem('auth.promo_data_analytics'.tr()),
          _buildPromoItem('auth.promo_support'.tr()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('auth.supplier_login'.tr(), style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('auth.apply_supplier'.tr(), style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
