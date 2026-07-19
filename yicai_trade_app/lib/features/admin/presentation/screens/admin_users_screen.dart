import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_provider.dart';

/// 用户管理页面 - 对应网站 admin.html 用户管理模块
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> get _tabs => [
    'admin.all'.tr(),
    'admin.buyers'.tr(),
    'admin.suppliers_count'.tr(),
    'admin.role_admin'.tr(),
  ];
  final _roleKeys = [null, 'BUYER', 'SUPPLIER', 'ADMIN'];
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(adminUsersProvider.notifier)
            .loadUsers(role: _roleKeys[_tabController.index]);
      }
    });
    Future.microtask(() => ref.read(adminUsersProvider.notifier).loadUsers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _showSearch
            ? _buildSearchBar()
            : Text('admin.users_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  ref
                      .read(adminUsersProvider.notifier)
                      .loadUsers(role: _roleKeys[_tabController.index]);
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.searchBarBg,
        borderRadius: AppRadius.pillBorder,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: AppTextStyles.bodyM,
        decoration: InputDecoration(
          hintText: 'admin.search_users'.tr(),
          hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 10),
          icon: Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textPlaceholder,
          ),
        ),
        onSubmitted: (v) {
          ref
              .read(adminUsersProvider.notifier)
              .loadUsers(role: _roleKeys[_tabController.index], keyword: v);
        },
      ),
    );
  }

  Widget _buildBody(AdminUsersState state) {
    if (state.isLoading) return const ListCardShimmer();
    if (state.error != null && state.users.isEmpty) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        onRetry: () => ref.read(adminUsersProvider.notifier).refresh(),
      );
    }
    if (state.users.isEmpty) {
      return EmptyWidget(
        icon: Icons.people_outline,
        message: 'admin.no_users'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminUsersProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.users.length,
        itemBuilder: (context, index) => _buildUserCard(state.users[index]),
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final roleColor = switch (user.role) {
      'ADMIN' => AppColors.secondary,
      'SUPPLIER' => AppColors.featureTeal,
      'BUYER' => AppColors.catBlue,
      _ => AppColors.textSecondary,
    };
    final isActive = user.status == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user.nickname ?? user.username).isNotEmpty
                        ? (user.nickname ?? user.username)[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.nickname ?? user.username,
                          style: AppTextStyles.bodyL.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.roleLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: roleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (user.email != null) user.email!,
                        if (user.phone != null) user.phone!,
                      ].join(' | '),
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 状态开关
              GestureDetector(
                onTap: () => _toggleStatus(user),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.successBg : AppColors.errorBg,
                    borderRadius: AppRadius.pillBorder,
                    border: Border.all(
                      color: isActive
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isActive ? 'common.normal'.tr() : 'common.disabled'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (user.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 12,
                  color: AppColors.textPlaceholder,
                ),
                const SizedBox(width: 4),
                Text(
                  '${'admin.registered'.tr()}: ${user.createdAt}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ],
          // 操作按钮行
          const SizedBox(height: 10),
          Row(
            children: [
              _userActionBtn(
                'admin.detail'.tr(),
                Icons.info_outline_rounded,
                AppColors.catBlue,
                () => _showUserDetail(user),
              ),
              const SizedBox(width: 10),
              _userActionBtn(
                'admin.role'.tr(),
                Icons.swap_horiz_rounded,
                AppColors.catPurple,
                () => _showChangeRole(user),
              ),
              const SizedBox(width: 10),
              _userActionBtn(
                'admin.reset_password'.tr(),
                Icons.lock_reset_outlined,
                AppColors.warning,
                () => _showResetPassword(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleStatus(AdminUser user) {
    final isActive = user.status == 'ACTIVE';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          isActive ? 'admin.disable_user'.tr() : 'admin.enable_user'.tr(),
          style: AppTextStyles.headingS,
        ),
        content: Text(
          isActive ? 'admin.disable_desc'.tr() : 'admin.enable_desc'.tr(),
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
              ref
                  .read(adminUsersProvider.notifier)
                  .toggleUserStatus(user.id, user.status);
            },
            child: Text(
              'common.confirm'.tr(),
              style: TextStyle(
                color: isActive ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.pillBorder,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetail(AdminUser user) {
    final roleColor = switch (user.role) {
      'ADMIN' => AppColors.secondary,
      'SUPPLIER' => AppColors.featureTeal,
      'BUYER' => AppColors.catBlue,
      _ => AppColors.textSecondary,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头像
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user.nickname ?? user.username).isNotEmpty
                      ? (user.nickname ?? user.username)[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.nickname ?? user.username,
              style: AppTextStyles.headingM.copyWith(
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.roleLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: roleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _detailRow('admin.user_id'.tr(), '${user.id}'),
            _detailRow('admin.username'.tr(), user.username),
            _detailRow('admin.email'.tr(), user.email ?? 'common.not_set'.tr()),
            _detailRow('admin.phone'.tr(), user.phone ?? 'common.not_set'.tr()),
            _detailRow(
              'common.status'.tr(),
              user.status == 'ACTIVE'
                  ? 'common.normal'.tr()
                  : 'common.disabled'.tr(),
            ),
            _detailRow(
              'admin.register_time'.tr(),
              user.createdAt ?? 'common.unknown'.tr(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRole(AdminUser user) {
    final roles = [
      ('BUYER', 'admin.buyers'.tr(), AppColors.catBlue),
      ('SUPPLIER', 'admin.suppliers_count'.tr(), AppColors.featureTeal),
      ('ADMIN', 'admin.role_admin'.tr(), AppColors.secondary),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text('admin.change_role'.tr(), style: AppTextStyles.headingS),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'admin.current_user'.tr()}: ${user.nickname ?? user.username}',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...roles.map((r) {
              final selected = user.role == r.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: selected
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _showSnack('admin.role_changed'.tr(args: [r.$2]));
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? r.$3.withValues(alpha: 0.12)
                          : AppColors.searchBarBg,
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(
                        color: selected
                            ? r.$3.withValues(alpha: 0.4)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: selected ? r.$3 : AppColors.textPlaceholder,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          r.$2,
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? r.$3 : AppColors.textBody,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (selected) ...[
                          const Spacer(),
                          Text(
                            'common.current'.tr(),
                            style: TextStyle(fontSize: 11, color: r.$3),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showResetPassword(AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text('admin.reset_password'.tr(), style: AppTextStyles.headingS),
        content: Text(
          'admin.reset_confirm'.tr(args: [user.nickname ?? user.username]),
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
              _showSnack('admin.reset_sent'.tr());
            },
            child: Text(
              'admin.confirm_reset'.tr(),
              style: TextStyle(color: AppColors.warning),
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
