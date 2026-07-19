/// 路由名称/路径常量
class RouteNames {
  RouteNames._();

  // 核心路径
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // 核心功能页面
  static const String smartMatch = '/smart-match';
  static const String auctionList = '/auctions';
  static const String auctionDetail = '/auctions/:id';
  static const String auctionCreate = '/auctions/create';
  static const String productionMonitor = '/production-monitor';
  static const String dashboard = '/dashboard';

  // 交易管理
  static const String orderDetail = '/orders/:id';
  static const String contractList = '/contracts';
  static const String contractDetail = '/contracts/:id';

  // 供应商
  static const String supplierList = '/suppliers';
  static const String supplierCenter = '/supplier-center';
  static const String supplierDetail = '/suppliers/:id';

  // 询盘 & 需求
  static const String inquiryList = '/inquiries';
  static const String publishDemand = '/publish-demand';

  // 沟通
  static const String chat = '/chat';

  // 供应商中心
  static const String supplierProducts = '/supplier-center/products';
  static const String supplierProductEdit = '/supplier-center/product-edit';
  static const String supplierOrders = '/supplier-center/orders';
  static const String supplierApply = '/supplier-apply';

  // 交付与监控
  static const String deliveryConfirm = '/delivery-confirm';
  static const String monitorSettings = '/monitor-settings';
  static const String monitorUpload = '/monitor-upload';

  // 个人中心子页面
  static const String accountSettings = '/account-settings';
  static const String securitySettings = '/security-settings';

  // 法律文本
  static const String aboutUs = '/about';
  static const String privacyPolicy = '/privacy';
  static const String termsOfService = '/terms';
  static const String serviceAgreement = '/service';

  // 新增功能页面
  static const String newsList = '/news';
  static const String newsDetail = '/news/:id';
  static const String wallet = '/wallet';
  static const String certification = '/certification';
  static const String helpCenter = '/help';

  // 三级/四级功能页面
  static const String quoteDetail = '/inquiries/quote/:id';
  static const String supplierOrderDetail = '/supplier-center/orders/:id';
  static const String productionDetail = '/production-monitor/:id';
  static const String contractCreate = '/contracts/create';
  static const String demandList = '/demands';
  static const String logisticsTracking = '/orders/:id/logistics';
  static const String supplierScore = '/suppliers/:id/score';
  static const String supplierMap = '/supplier-map';

  // 后台管理
  static const String adminPanel = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminSettings = '/admin/settings';
  static const String adminStatistics = '/admin/statistics';
  static const String adminContent = '/admin/content';
}
