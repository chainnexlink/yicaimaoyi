// API 路径常量 - 通过 Nginx 反向代理访问 Spring Boot 后端
class ApiConstants {
  ApiConstants._();

  /// Production API for iOS, Android and web. Local development can override
  /// this with `--dart-define=API_BASE_URL=http://10.0.2.2:8081`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.chainnexlink.com',
  );

  static const String apiPrefix = '/api';

  // ============ Auth 认证 ============
  static const String authLogin = '$apiPrefix/auth/login';
  static const String authRegister = '$apiPrefix/auth/register';
  static const String authRefresh = '$apiPrefix/auth/refresh';
  static const String authMe = '$apiPrefix/auth/me';
  static const String authLogout = '$apiPrefix/auth/logout';
  static const String authSendCode = '$apiPrefix/auth/send-code';
  static const String authCodeLogin = '$apiPrefix/auth/code-login';
  static const String authWechatLogin = '$apiPrefix/auth/wechat/login';
  static const String authWechatBindPhone = '$apiPrefix/auth/wechat/bind-phone';

  // ============ User 用户资料 ============
  static const String userProfile = '$apiPrefix/user/profile';

  // ============ Auction 竞价 ============
  static const String auctionList = '$apiPrefix/v1/auction/list';
  static const String auctionHome = '$apiPrefix/v1/auction/home';
  static const String auctionCreate = '$apiPrefix/v1/auction/create';
  static const String auctionBase = '$apiPrefix/v1/auction';
  static const String auctionMy = '$apiPrefix/v1/auction/my';
  static const String auctionBid = '$apiPrefix/v1/auction/bid';
  // 竞价扩展端点 (匹配网站 auction-detail.html)
  static String auctionDetail(int id) => '$auctionBase/$id';
  static String auctionMyStatus(int id) => '$auctionBase/$id/my-status';
  static String auctionMyRanking(int id) => '$auctionBase/$id/my-ranking';
  static String auctionSignup(int id) => '$auctionBase/$id/signup';
  static String auctionBuyerConfirm(int id) => '$auctionBase/$id/buyer-confirm';
  static String auctionSupplierConfirm(int id) =>
      '$auctionBase/$id/supplier-confirm';
  static String auctionPublish(int id) => '$auctionBase/$id/publish';
  static String auctionCancel(int id) => '$auctionBase/$id/cancel';
  static String auctionReAuction(int id) => '$auctionBase/$id/re-auction';
  static String auctionBids(int id) => '$auctionBase/$id/bids';

  // ============ Auction Deposit 竞价押金 ============
  static const String depositBase = '$apiPrefix/v1/auction/deposit';
  static const String depositAdminConfig = '$depositBase/admin/config';
  static const String depositVouchersMy = '$depositBase/vouchers/my';
  static const String depositCheck = '$depositBase/check';
  static const String depositSupplierPay = '$depositBase/supplier/pay';
  static const String depositBuyerPay = '$depositBase/buyer/pay';

  // ============ Smart Match 智能匹配 ============
  static const String smartMatchCategories =
      '$apiPrefix/v1/smart-match/categories';
  static const String smartMatchParametersCost =
      '$apiPrefix/v1/smart-match/parameters/cost';
  static const String smartMatchEstimateCost =
      '$apiPrefix/v1/smart-match/estimate/cost';
  static const String smartMatchEstimateFactoryQuote =
      '$apiPrefix/v1/smart-match/estimate/factory-quote';
  static const String smartMatchParametersFob =
      '$apiPrefix/v1/smart-match/parameters/fob';
  static const String smartMatchEstimateFob =
      '$apiPrefix/v1/smart-match/estimate/fob';

  // ============ Order 订单 ============
  static const String orders = '$apiPrefix/orders';
  // 用户级: /api/orders/buyer/{buyerId} 或 /api/orders/supplier/{supplierId}
  static String ordersByBuyer(int buyerId) => '$orders/buyer/$buyerId';
  static String ordersBySupplier(int supplierId) =>
      '$orders/supplier/$supplierId';

  // ============ Contract 合同 ============
  static const String contracts = '$apiPrefix/contracts';
  static const String contractTemplates = '$apiPrefix/contracts/templates';
  static String contractsByBuyer(int buyerId) => '$contracts/buyer/$buyerId';
  static String contractsBySupplier(int supplierId) =>
      '$contracts/supplier/$supplierId';

  // ============ Payment 支付 ============
  static const String payments = '$apiPrefix/payments';
  static const String paymentsMy = '$apiPrefix/payments/my';
  static const String refunds = '$apiPrefix/payments/refunds';

  // ============ Supplier 供应商 ============
  static const String supplierProfile = '$apiPrefix/supplier/profile';
  static const String supplierProducts = '$apiPrefix/supplier/products';
  static const String supplierApply = '$apiPrefix/supplier/apply';
  static const String adminSuppliers = '$apiPrefix/admin/suppliers';

  // ============ Buyer 采购商 ============
  static const String buyerProfile = '$apiPrefix/buyer/profile';
  static const String buyerFavorites = '$apiPrefix/buyer/favorites';

  // ============ Inquiry 询价 ============
  static const String inquiries = '$apiPrefix/inquiries';
  static const String inquiriesOpen = '$apiPrefix/inquiries/open';
  static String inquiriesByBuyer(int buyerId) => '$inquiries/buyer/$buyerId';

  // ============ Monitor 生产监控 ============
  static const String monitors = '$apiPrefix/monitors';
  static const String monitorUpload = '$apiPrefix/monitors/upload';
  static String monitorsByBuyer(int buyerId) => '$monitors/buyer/$buyerId';
  static String monitorsBySupplier(int supplierId) =>
      '$monitors/supplier/$supplierId';
  static String monitorAlertsByBuyer(int buyerId) =>
      '$monitors/alerts/buyer/$buyerId';
  // 监控扩展端点 (匹配后端 MonitorController)
  static String monitorActiveAlertCount(int buyerId) =>
      '$monitors/alerts/buyer/$buyerId/active-count';
  static String monitorDetail(int id) => '$monitors/$id';
  static String monitorByOrder(int orderId) => '$monitors/order/$orderId';

  // ============ Wallet 钱包 ============
  static const String wallet = '$apiPrefix/wallet';

  // ============ Message 消息 ============
  static const String messages = '$apiPrefix/admin/messages';
  static String messagesByUser(int userId) => '$messages/user/$userId';
  static String messagesUnreadByUser(int userId) =>
      '$messages/user/$userId/unread';
  static String messagesUnreadCount(int userId) =>
      '$messages/user/$userId/unread-count';
  static String messagesReadAll(int userId) =>
      '$messages/user/$userId/read-all';

  // ============ News 新闻 ============
  static const String news = '$apiPrefix/news';

  // ============ Content Banner ============
  static const String bannersActive = '$apiPrefix/admin/content/banners/active';

  // ============ AI Chat ============
  static const String aiChatMessage = '$apiPrefix/ai-chat/message';

  // ============ Certification 认证 ============
  static const String certificationUpload = '$apiPrefix/certification/upload';

  // ============ Logistics 物流 ============
  static const String logistics = '$apiPrefix/admin/logistics';

  // ============ Review 评价 ============
  static const String review = '$apiPrefix/review';

  // ============ Aftersale 售后 ============
  static const String aftersale = '$apiPrefix/aftersale';

  // ============ Dispute 纠纷 ============
  static const String dispute = '$apiPrefix/dispute';

  // ============ Invoice 发票 ============
  static const String invoice = '$apiPrefix/invoice';

  // ============ Dashboard 看板 ============
  static const String dashboardStats = '$apiPrefix/admin/dashboard/stats';

  // ============ Demand 需求 ============
  static const String demands = '$apiPrefix/admin/demands';
  static String demandsByBuyer(int buyerId) => '$demands/buyer/$buyerId';

  // ============ Escrow 托管 ============
  static const String escrow = '$apiPrefix/escrow';

  // ============ WebSocket ============
  static const String wsEndpoint = '/ws';

  // ============ Shop ============
  static const String shop = '$apiPrefix/shop';

  // ============ Review Detail ============
  static String reviewByOrder(int orderId) => '$review/order/$orderId';
  static String reviewBySupplier(int supplierId) =>
      '$review/supplier/$supplierId';
  static String reviewByBuyer(int buyerId) => '$review/buyer/$buyerId';

  // ============ Supplier Credit ============
  static const String supplierCredit = '$apiPrefix/supplier-credit';

  // ============ Escrow Detail ============
  static String escrowByOrder(int orderId) => '$escrow/order/$orderId';
  static String escrowByBuyer(int buyerId) => '$escrow/buyer/$buyerId';
  static String escrowBySupplier(int supplierId) =>
      '$escrow/supplier/$supplierId';

  // ============ Payment Detail ============
  static String paymentsByOrder(int orderId) => '$payments/order/$orderId';
  static const String paymentsReceived = '$apiPrefix/payments/received';
  static const String refundsPending = '$apiPrefix/payments/refunds/pending';
  static String refundsByOrder(int orderId) => '$refunds/order/$orderId';
  static const String refundsMy = '$apiPrefix/payments/refunds/my';

  // ============ Wallet Detail ============
  static String walletGet(String ownerType, int ownerId) =>
      '$wallet/$ownerType/$ownerId';
  static String walletTransactions(String ownerType, int ownerId) =>
      '$wallet/$ownerType/$ownerId/transactions';
  static String walletRecharge(String ownerType, int ownerId) =>
      '$wallet/$ownerType/$ownerId/recharge';
  static String walletWithdraw(String ownerType, int ownerId) =>
      '$wallet/$ownerType/$ownerId/withdraw';

  // ============ Logistics Detail ============
  static String logisticsDetail(int id) => '$logistics/$id';
  static String logisticsTracking(String trackingNo) =>
      '$logistics/tracking/$trackingNo';
  static const String logisticsTrack = '$apiPrefix/admin/logistics/track';

  // ============ Shop Detail ============
  static String shopDetail(int id) => '$shop/$id';
  static String shopBySupplier(int supplierId) => '$shop/supplier/$supplierId';
  static String shopDashboard(int supplierId) =>
      '$shop/supplier/$supplierId/dashboard';
  static String shopUpdateInfo(int supplierId) =>
      '$shop/supplier/$supplierId/info';
  static String shopUpdateDecoration(int supplierId) =>
      '$shop/supplier/$supplierId/decoration';

  // ============ Wallet Commission ============
  static const String walletCommission = '$wallet/commission';
  static String walletCommissionByBuyer(int buyerId) =>
      '$walletCommission/buyer/$buyerId';
  static String walletCommissionByContract(int contractId) =>
      '$walletCommission/contract/$contractId';

  // ============ Demand Detail ============
  static String demandDetail(int id) => '$demands/$id';

  // ============ News Detail ============
  static const String newsLatest = '$apiPrefix/news/latest';
  static const String newsList = '$apiPrefix/news/list';
  static String newsDetail(int id) => '$news/$id';
  static const String newsIndustries = '$apiPrefix/news/industries';

  // ============ AI Chat Detail ============
  static const String aiChatHealth = '$apiPrefix/ai-chat/health';

  // ============ Review Detail Extra ============
  static String reviewReply(int id) => '$review/$id/reply';
  static String reviewSummary(int supplierId) =>
      '$review/supplier/$supplierId/summary';

  static const List<String> publicPaths = [
    authLogin,
    authRegister,
    authRefresh,
    authSendCode,
    authCodeLogin,
    authWechatLogin,
    auctionList,
    auctionHome,
    smartMatchCategories,
    smartMatchEstimateCost,
    smartMatchEstimateFob,
    inquiriesOpen,
    news,
    bannersActive,
  ];

  static bool isPublicPath(String path) {
    return publicPaths.any((p) => path.startsWith(p));
  }
}
