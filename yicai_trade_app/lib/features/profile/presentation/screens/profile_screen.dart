import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/router/route_names.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_info.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// 个人中心页面 - V2 主题重新设计
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    // 加载钱包数据（仅在无数据且无错误时触发一次）
    final walletState = ref.watch(walletProvider);
    if (user != null &&
        walletState.wallet == null &&
        !walletState.isLoading &&
        walletState.error == null) {
      Future.microtask(() => ref.read(walletProvider.notifier).loadWallet());
    }
    final walletBalance = walletState.wallet?.balance ?? 0.0;
    final walletFrozen = walletState.wallet?.frozenAmount ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildGradientHeader(context, user),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStatsRow(context),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildWalletCard(context, walletBalance, walletFrozen),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildQuickActions(context),
          ),

          _buildSectionHeader('profile.section_account'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.person_outline_rounded,
                'profile.personal_info'.tr(),
                AppColors.primary,
                () => context.push(RouteNames.accountSettings),
              ),
              _MenuItem(
                Icons.business_outlined,
                'profile.company_info'.tr(),
                AppColors.catPurple,
                () => context.push(RouteNames.accountSettings),
              ),
              _MenuItem(
                Icons.shield_outlined,
                'profile.security_settings'.tr(),
                AppColors.featureTeal,
                () => context.push(RouteNames.securitySettings),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_trade'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.receipt_long_outlined,
                'profile.my_orders'.tr(),
                AppColors.primary,
                () => context.go(RouteNames.orders),
              ),
              _MenuItem(
                Icons.local_shipping_outlined,
                'profile.order_tracking'.tr(),
                AppColors.featureTeal,
                () => context.push(RouteNames.productionMonitor),
              ),
              _MenuItem(
                Icons.bar_chart_rounded,
                'profile.order_stats'.tr(),
                AppColors.catOrange,
                () => context.push(RouteNames.dashboard),
              ),
              _MenuItem(
                Icons.description_outlined,
                'profile.my_contracts'.tr(),
                AppColors.catPurple,
                () => context.push(RouteNames.contractList),
              ),
              _MenuItem(
                Icons.draw_outlined,
                'profile.pending_sign'.tr(),
                AppColors.warning,
                () => context.push(RouteNames.contractList),
              ),
              _MenuItem(
                Icons.file_copy_outlined,
                'profile.contract_templates'.tr(),
                AppColors.textSecondary,
                () => context.push(RouteNames.contractList),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_demand'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.list_alt_rounded,
                'profile.demand_list'.tr(),
                AppColors.featureYellow,
                () => context.push(RouteNames.publishDemand),
              ),
              _MenuItem(
                Icons.post_add_rounded,
                'profile.publish_demand'.tr(),
                AppColors.success,
                () => context.push(RouteNames.publishDemand),
              ),
              _MenuItem(
                Icons.request_quote_outlined,
                'profile.quote_manage'.tr(),
                AppColors.secondary,
                () => context.push(RouteNames.inquiryList),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_supplier'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.factory_outlined,
                'profile.my_suppliers'.tr(),
                AppColors.primary,
                () => context.push(RouteNames.supplierList),
              ),
              _MenuItem(
                Icons.star_outline_rounded,
                'profile.supplier_rating'.tr(),
                AppColors.featureYellow,
                () => context.push(RouteNames.supplierList),
              ),
              _MenuItem(
                Icons.block_outlined,
                'profile.blacklist'.tr(),
                AppColors.error,
                () => context.push(RouteNames.supplierList),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_production'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.precision_manufacturing_outlined,
                'profile.production_progress'.tr(),
                AppColors.featureTeal,
                () => context.push(RouteNames.productionMonitor),
              ),
              _MenuItem(
                Icons.assignment_turned_in_outlined,
                'profile.quality_report'.tr(),
                AppColors.success,
                () => context.push(RouteNames.productionMonitor),
              ),
              _MenuItem(
                Icons.notification_important_outlined,
                'profile.alert_center'.tr(),
                AppColors.error,
                () => context.push(RouteNames.productionMonitor),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_communication'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.chat_bubble_outline_rounded,
                'profile.message_list'.tr(),
                AppColors.primary,
                () => context.go(RouteNames.messages),
              ),
              _MenuItem(
                Icons.question_answer_outlined,
                'profile.my_inquiries'.tr(),
                AppColors.featureYellow,
                () => context.push(RouteNames.inquiryList),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_analytics'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.analytics_outlined,
                'profile.purchase_analytics'.tr(),
                AppColors.catPurple,
                () => context.push(RouteNames.dashboard),
              ),
              _MenuItem(
                Icons.summarize_outlined,
                'profile.report_center'.tr(),
                AppColors.catTeal,
                () => context.push(RouteNames.dashboard),
              ),
            ]),
          ),

          _buildSectionHeader('profile.section_member'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.card_membership_outlined,
                'profile.membership_benefits'.tr(),
                AppColors.secondary,
                () => context.push(RouteNames.wallet),
              ),
              _MenuItem(
                Icons.monetization_on_outlined,
                'profile.points_detail'.tr(),
                AppColors.featureYellow,
                () => context.push(RouteNames.wallet),
              ),
            ]),
          ),

          // 管理后台 (仅管理员可见)
          if (user?.userType == 'ADMIN') ...[
            _buildSectionHeader('profile.section_admin'.tr()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMenuSection(context, [
                _MenuItem(
                  Icons.admin_panel_settings_outlined,
                  'profile.admin_panel'.tr(),
                  AppColors.error,
                  () => context.push(RouteNames.adminPanel),
                ),
                _MenuItem(
                  Icons.people_outline_rounded,
                  'profile.admin_users'.tr(),
                  AppColors.catPurple,
                  () => context.push(RouteNames.adminUsers),
                ),
                _MenuItem(
                  Icons.assignment_outlined,
                  'profile.admin_orders'.tr(),
                  AppColors.catOrange,
                  () => context.push(RouteNames.adminOrders),
                ),
                _MenuItem(
                  Icons.bar_chart_rounded,
                  'profile.admin_statistics'.tr(),
                  AppColors.catBlue,
                  () => context.push(RouteNames.adminStatistics),
                ),
                _MenuItem(
                  Icons.article_outlined,
                  'profile.admin_content'.tr(),
                  AppColors.featureTeal,
                  () => context.push(RouteNames.adminContent),
                ),
                _MenuItem(
                  Icons.tune_rounded,
                  'profile.admin_settings'.tr(),
                  AppColors.warning,
                  () => context.push(RouteNames.adminSettings),
                ),
              ]),
            ),
          ],

          _buildSectionHeader('profile.section_other'.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMenuSection(context, [
              _MenuItem(
                Icons.verified_outlined,
                'profile.certification'.tr(),
                AppColors.success,
                () => context.push(RouteNames.certification),
              ),
              _MenuItem(
                Icons.favorite_border_rounded,
                'profile.my_favorites'.tr(),
                AppColors.featureRed,
                () => context.push(RouteNames.supplierList),
              ),
              _MenuItem(
                Icons.help_outline_rounded,
                'profile.help'.tr(),
                AppColors.textSecondary,
                () => context.push(RouteNames.helpCenter),
              ),
              _MenuItem(
                Icons.info_outline_rounded,
                'profile.about'.tr(),
                AppColors.textSecondary,
                () => context.push(RouteNames.aboutUs),
              ),
              _MenuItem(
                Icons.settings_outlined,
                'profile.settings'.tr(),
                AppColors.textSecondary,
                () => context.push(RouteNames.settings),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(RouteNames.login);
                    }
                  },
                  borderRadius: AppRadius.mdBorder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'auth.logout'.tr(),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ==========================================================
  // 渐变头部 - 蓝色专业风格
  // ==========================================================
  Widget _buildGradientHeader(BuildContext context, UserInfo? user) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
        ),
      ),
      child: Column(
        children: [
          // 顶部操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.title'.tr(),
                style: AppTextStyles.headingM.copyWith(
                  color: AppColors.textTitle,
                ),
              ),
              Row(
                children: [
                  _buildHeaderAction(Icons.qr_code_scanner_rounded, () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('profile.scan_coming_soon'.tr())));
                  }),
                  const SizedBox(width: 4),
                  _buildHeaderAction(
                    Icons.settings_outlined,
                    () => context.push(RouteNames.settings),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 用户信息行
          Row(
            children: [
              // 头像
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.featureTeal.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    user != null
                        ? user.displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.displayName ?? 'profile.not_logged_in'.tr(),
                            style: AppTextStyles.headingS.copyWith(
                              color: AppColors.textTitle,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: AppRadius.pillBorder,
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              user.userType == 'SUPPLIER' ? 'profile.role_supplier'.tr() : 'profile.role_buyer'.tr(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? (user.email ?? user.phone ?? user.userType)
                          : 'profile.login_prompt'.tr(),
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // 会员标识
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 12,
                                  color: Color(0xFF5D3600),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'profile.member_badge'.tr(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF5D3600),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 申请入驻
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  context.push(RouteNames.supplierApply),
                              borderRadius: AppRadius.pillBorder,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                child: Text(
                                  'profile.apply_supplier'.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPlaceholder,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // ==========================================================
  // 数据概览 - 4 格统计卡片
  // ==========================================================
  Widget _buildStatsRow(BuildContext context) {
    final items = [
      _StatItem(
        'profile.stat_orders'.tr(),
        AppColors.primary,
        () => context.go(RouteNames.orders),
      ),
      _StatItem(
        'profile.stat_demands'.tr(),
        AppColors.featureYellow,
        () => context.push(RouteNames.demandList),
      ),
      _StatItem(
        'profile.stat_suppliers'.tr(),
        AppColors.featureTeal,
        () => context.push(RouteNames.supplierList),
      ),
      _StatItem(
        'profile.stat_contracts'.tr(),
        AppColors.catPurple,
        () => context.push(RouteNames.contractList),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: GestureDetector(
              onTap: item.onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Icon(
                    Icons.chevron_right_rounded,
                    color: item.color,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // 零钱卡片
  // ==========================================================
  Widget _buildWalletCard(BuildContext context, double balance, double frozen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RouteNames.wallet),
        borderRadius: AppRadius.lgBorder,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2137), Color(0xFF0A3D2E)],
            ),
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            boxShadow: AppShadows.cardMedium,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.wallet_title'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        text: '${'profile.wallet_balance'.tr()} ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: '\u00a5${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u00a5${frozen.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'profile.wallet_rebate_total'.tr(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPlaceholder,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 快捷操作
  // ==========================================================
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        Icons.post_add_rounded,
        'profile.quick_publish_demand'.tr(),
        'profile.quick_publish_demand_desc'.tr(),
        AppColors.featureYellow,
        () => context.push(RouteNames.publishDemand),
      ),
      _QuickAction(
        Icons.receipt_long_outlined,
        'profile.quick_order_manage'.tr(),
        'profile.quick_order_manage_desc'.tr(),
        AppColors.primary,
        () => context.go(RouteNames.orders),
      ),
      _QuickAction(
        Icons.chat_bubble_outline_rounded,
        'profile.quick_messages'.tr(),
        'profile.quick_messages_desc'.tr(),
        AppColors.featureTeal,
        () => context.go(RouteNames.messages),
      ),
      _QuickAction(
        Icons.description_outlined,
        'profile.quick_contracts'.tr(),
        'profile.quick_contracts_desc'.tr(),
        AppColors.catPurple,
        () => context.push(RouteNames.contractList),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: AppRadius.mdBorder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              action.color.withValues(alpha: 0.2),
                              action.color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: action.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.label,
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textTitle,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.desc,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textPlaceholder,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // 分组标题
  // ==========================================================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 菜单卡片组
  // ==========================================================
  Widget _buildMenuSection(BuildContext context, List<_MenuItem> items) {
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
                                item.iconColor.withValues(alpha: 0.2),
                                item.iconColor.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.iconColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: AppTextStyles.bodyL.copyWith(
                              color: AppColors.textTitle,
                            ),
                          ),
                        ),
                        Icon(
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
}

// ==========================================================
// 数据模型
// ==========================================================
class _MenuItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.iconColor, this.onTap);
}

class _StatItem {
  final String label;
  final Color color;
  final VoidCallback onTap;
  _StatItem(this.label, this.color, this.onTap);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.icon, this.label, this.desc, this.color, this.onTap);
}
