import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'route_names.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/smart_match/presentation/screens/smart_match_screen.dart';
import '../../features/auction/presentation/screens/auction_list_screen.dart';
import '../../features/auction/presentation/screens/auction_detail_screen.dart';
import '../../features/auction/presentation/screens/create_auction_screen.dart';
import '../../features/production/presentation/screens/production_monitor_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/contract/presentation/screens/contract_screen.dart';
import '../../features/contract/presentation/screens/contract_detail_screen.dart';
import '../../features/supplier/presentation/screens/supplier_list_screen.dart';
import '../../features/supplier/presentation/screens/supplier_detail_screen.dart';
import '../../features/inquiry/presentation/screens/inquiry_screen.dart';
import '../../features/demand/presentation/screens/publish_demand_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/news/presentation/screens/news_screen.dart';
import '../../features/news/presentation/screens/news_detail_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/certification/presentation/screens/certification_screen.dart';
import '../../features/help/presentation/screens/help_center_screen.dart';
import '../../features/supplier_center/presentation/screens/supplier_center_screen.dart';
import '../../features/supplier_center/presentation/screens/supplier_products_screen.dart';
import '../../features/supplier_center/presentation/screens/supplier_product_edit_screen.dart';
import '../../features/supplier_center/presentation/screens/supplier_orders_screen.dart';
import '../../features/supplier_center/presentation/screens/supplier_apply_screen.dart';
import '../../features/supplier_center/presentation/screens/delivery_confirm_screen.dart';
import '../../features/supplier_center/presentation/screens/monitor_settings_screen.dart';
import '../../features/supplier_center/presentation/screens/monitor_upload_screen.dart';
import '../../features/profile/presentation/screens/account_settings_screen.dart';
import '../../features/profile/presentation/screens/security_settings_screen.dart';
import '../../features/settings/presentation/screens/legal_page_screen.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_statistics_screen.dart';
import '../../features/admin/presentation/screens/admin_content_screen.dart';
import '../../features/inquiry/presentation/screens/quote_detail_screen.dart';
import '../../features/supplier_center/presentation/screens/supplier_order_detail_screen.dart';
import '../../features/production/presentation/screens/production_detail_screen.dart';
import '../../features/contract/presentation/screens/contract_create_screen.dart';
import '../../features/demand/presentation/screens/demand_list_screen.dart';
import '../../features/orders/presentation/screens/logistics_tracking_screen.dart';
import '../../features/supplier/presentation/screens/supplier_score_screen.dart';
import '../../features/supplier/presentation/screens/supplier_map_screen.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

/// 认证状态变化通知器 - 用于 GoRouter.refreshListenable
class AuthChangeNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void update(bool loggedIn) {
    if (_isLoggedIn != loggedIn) {
      _isLoggedIn = loggedIn;
      notifyListeners();
    }
  }
}

/// GoRouter 主路由配置 - 只创建一次
GoRouter createRouter({required AuthChangeNotifier authNotifier}) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final path = state.uri.path;
      final isSplash = path == RouteNames.splash;
      final isLoginRoute =
          path == RouteNames.login || path == RouteNames.register;
      final isOnboarding = path == RouteNames.onboarding;

      // Splash 页始终放行
      if (isSplash) return null;

      // 引导页：已登录时放行
      if (isOnboarding && isLoggedIn) return null;

      // 未登录且访问受保护路由 -> 重定向到登录
      if (!isLoggedIn && !isLoginRoute) {
        return RouteNames.login;
      }

      // 已登录且访问登录页 -> 重定向到首页
      if (isLoggedIn && isLoginRoute) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      // Splash 启动页
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 登录页
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // 注册页 (复用 LoginScreen，初始显示注册 Tab)
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const LoginScreen(initialTabIndex: 2),
      ),

      // 新手引导页
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 主页面 - 底部导航 Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: 首页
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 1: 订单管理
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),

          // Tab 2: 消息中心
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.messages,
                builder: (context, state) => const MessagesScreen(),
              ),
            ],
          ),

          // Tab 3: 我的
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ====== 二级功能页面 ======

      // 设置页
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // AI智能匹配
      GoRoute(
        path: RouteNames.smartMatch,
        builder: (context, state) => const SmartMatchScreen(),
      ),

      // 反向竞价列表
      GoRoute(
        path: RouteNames.auctionList,
        builder: (context, state) => const AuctionListScreen(),
      ),

      // 发起竞价 (必须在 :id 之前定义，避免 GoRouter 将 "create" 匹配为 id)
      GoRoute(
        path: RouteNames.auctionCreate,
        builder: (context, state) => const CreateAuctionScreen(),
      ),

      // 竞价详情
      GoRoute(
        path: RouteNames.auctionDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AuctionDetailScreen(auctionId: id);
        },
      ),

      // 生产监控
      GoRoute(
        path: RouteNames.productionMonitor,
        builder: (context, state) => const ProductionMonitorScreen(),
      ),

      // 数据看板
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // 合同管理
      GoRoute(
        path: RouteNames.contractList,
        builder: (context, state) => const ContractScreen(),
      ),

      // 合同详情
      GoRoute(
        path: RouteNames.contractDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ContractDetailScreen(contractId: id);
        },
      ),

      // 订单详情
      GoRoute(
        path: RouteNames.orderDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return OrderDetailScreen(orderId: id);
        },
      ),

      // 供应商库
      GoRoute(
        path: RouteNames.supplierList,
        builder: (context, state) => const SupplierListScreen(),
      ),

      // 供应商详情
      GoRoute(
        path: RouteNames.supplierDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return SupplierDetailScreen(supplierId: id);
        },
      ),

      // 询盘管理
      GoRoute(
        path: RouteNames.inquiryList,
        builder: (context, state) => const InquiryScreen(),
      ),

      // 发布需求
      GoRoute(
        path: RouteNames.publishDemand,
        builder: (context, state) => const PublishDemandScreen(),
      ),

      // 即时通讯
      GoRoute(
        path: RouteNames.chat,
        builder: (context, state) => const ChatListScreen(),
      ),

      // 新闻资讯
      GoRoute(
        path: RouteNames.newsList,
        builder: (context, state) => const NewsListScreen(),
      ),

      // 新闻详情
      GoRoute(
        path: RouteNames.newsDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return NewsDetailScreen(articleId: id);
        },
      ),

      // 钱包
      GoRoute(
        path: RouteNames.wallet,
        builder: (context, state) => const WalletScreen(),
      ),

      // 资质认证
      GoRoute(
        path: RouteNames.certification,
        builder: (context, state) => const CertificationScreen(),
      ),

      // 帮助中心
      GoRoute(
        path: RouteNames.helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),

      // ====== 供应商中心模块 ======

      // 供应商中心工作台
      GoRoute(
        path: RouteNames.supplierCenter,
        builder: (context, state) => const SupplierCenterScreen(),
      ),

      // 供应商产品管理
      GoRoute(
        path: RouteNames.supplierProducts,
        builder: (context, state) => const SupplierProductsScreen(),
      ),

      // 供应商产品编辑/添加
      GoRoute(
        path: RouteNames.supplierProductEdit,
        builder: (context, state) {
          final idStr = state.uri.queryParameters['id'];
          final id = idStr != null ? int.tryParse(idStr) : null;
          return SupplierProductEditScreen(productId: id);
        },
      ),

      // 供应商订单管理
      GoRoute(
        path: RouteNames.supplierOrders,
        builder: (context, state) => const SupplierOrdersScreen(),
      ),

      // 供应商入驻申请
      GoRoute(
        path: RouteNames.supplierApply,
        builder: (context, state) => const SupplierApplyScreen(),
      ),

      // 交付确认
      GoRoute(
        path: RouteNames.deliveryConfirm,
        builder: (context, state) => const DeliveryConfirmScreen(),
      ),

      // 监控设置
      GoRoute(
        path: RouteNames.monitorSettings,
        builder: (context, state) => const MonitorSettingsScreen(),
      ),

      // 进度上传
      GoRoute(
        path: RouteNames.monitorUpload,
        builder: (context, state) => const MonitorUploadScreen(),
      ),

      // ====== 个人中心子页面 ======

      // 账户设置
      GoRoute(
        path: RouteNames.accountSettings,
        builder: (context, state) => const AccountSettingsScreen(),
      ),

      // 安全设置
      GoRoute(
        path: RouteNames.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),

      // ====== 后台管理模块 ======

      // 管理后台主页
      GoRoute(
        path: RouteNames.adminPanel,
        builder: (context, state) => const AdminPanelScreen(),
      ),

      // 用户管理
      GoRoute(
        path: RouteNames.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),

      // 订单审核
      GoRoute(
        path: RouteNames.adminOrders,
        builder: (context, state) => const AdminOrdersScreen(),
      ),

      // 系统设置
      GoRoute(
        path: RouteNames.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      // 数据统计
      GoRoute(
        path: RouteNames.adminStatistics,
        builder: (context, state) => const AdminStatisticsScreen(),
      ),

      // 内容管理
      GoRoute(
        path: RouteNames.adminContent,
        builder: (context, state) => const AdminContentScreen(),
      ),

      // ====== 三级/四级功能页面 ======

      // 报价详情
      GoRoute(
        path: RouteNames.quoteDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return QuoteDetailScreen(quoteId: id);
        },
      ),

      // 供应商订单详情
      GoRoute(
        path: RouteNames.supplierOrderDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return SupplierOrderDetailScreen(orderId: id);
        },
      ),

      // 生产详情
      GoRoute(
        path: RouteNames.productionDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ProductionDetailScreen(monitorId: id);
        },
      ),

      // 创建合同
      GoRoute(
        path: RouteNames.contractCreate,
        builder: (context, state) => const ContractCreateScreen(),
      ),

      // 需求列表
      GoRoute(
        path: RouteNames.demandList,
        builder: (context, state) => const DemandListScreen(),
      ),

      // 物流追踪
      GoRoute(
        path: RouteNames.logisticsTracking,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return LogisticsTrackingScreen(orderId: id);
        },
      ),

      // 供应商评分
      GoRoute(
        path: RouteNames.supplierScore,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return SupplierScoreScreen(supplierId: id);
        },
      ),

      // 供应商地图
      GoRoute(
        path: RouteNames.supplierMap,
        builder: (context, state) => const SupplierMapScreen(),
      ),

      // ====== 法律文本页面 ======

      // 关于我们
      GoRoute(
        path: RouteNames.aboutUs,
        builder: (context, state) =>
            LegalPageScreen(title: 'settings.about_us'.tr(), type: 'about'),
      ),

      // 隐私政策
      GoRoute(
        path: RouteNames.privacyPolicy,
        builder: (context, state) =>
            LegalPageScreen(title: 'settings.privacy_policy'.tr(), type: 'privacy'),
      ),

      // 服务条款
      GoRoute(
        path: RouteNames.termsOfService,
        builder: (context, state) =>
            LegalPageScreen(title: 'settings.terms_of_service'.tr(), type: 'terms'),
      ),

      // 服务协议
      GoRoute(
        path: RouteNames.serviceAgreement,
        builder: (context, state) =>
            LegalPageScreen(title: 'settings.service_agreement'.tr(), type: 'service'),
      ),
    ],
  );
}
