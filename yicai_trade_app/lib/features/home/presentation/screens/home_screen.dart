import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../providers/home_provider.dart';
import '../widgets/mobile_workbench.dart';

/// App-native sourcing workbench.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeProvider.notifier).loadData());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: () => ref.read(homeProvider.notifier).loadData(),
          child: CustomScrollView(
            slivers: [
              // ---- SliverAppBar: 白色 + Logo + 搜索栏 ----
              SliverAppBar(
                pinned: true,
                toolbarHeight: 64,
                backgroundColor: Colors.white.withValues(alpha: 0.96),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0.3,
                title: Row(
                  children: [
                    // Logo
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'YC',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'app_name'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'app_home.workspace'.tr(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => context.push(RouteNames.supplierList),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => context.go(RouteNames.messages),
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ---- Section 1: Hero Banner ----
              const SliverToBoxAdapter(child: MobileWorkbench()),

              // ---- Section 2: 快速入口网格 ----

              // ---- Section 3: 三大核心功能卡 ----

              // ---- Section 4: 智能匹配入口 ----

              // ---- Section 5: 反向竞价优势 ----

              // ---- Section 6: 实时监控面板 ----

              // ---- Section 7: 智能采购反向竞价 ----

              // ---- Section 8: 平台资讯 ----

              // ---- 底部安全区 ----
            ],
          ),
        ),
      ),
    );
  }

  /// 快速入口区块
}
