import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/auction_model.dart';

/// Auction repository - matches backend AuctionController endpoints
/// Falls back to Mock data when backend is unavailable
class AuctionRepository {
  final Dio _dio;
  AuctionRepository(this._dio);

  // ============ Mock data (used when backend is unavailable) ============

  static List<AuctionModel> get _mockAuctions => [
    AuctionModel(
      id: 1,
      title: 'auction.demo_title_1'.tr(),
      status: 'BIDDING',
      bidderCount: 8,
      currentLowest: 12500.00,
      quantity: '50${'auction.demo_unit_ton'.tr()}',
      targetPrice: 15000.00,
      description: 'auction.demo_desc_1'.tr(),
      startTime: DateTime.now().subtract(const Duration(hours: 6)),
      endTime: DateTime.now().add(const Duration(hours: 18)),
      tags: ['auction.demo_tag_metal'.tr(), 'auction.demo_tag_stainless'.tr(), 'auction.demo_tag_urgent'.tr()],
      creatorId: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      auctionNo: 'AUC-2026-0001',
      productName: 'auction.demo_product_1'.tr(),
      productCategory: 'auction.demo_category_metal'.tr(),
      specification: 'auction.demo_spec_1'.tr(),
      unit: 'auction.demo_unit_ton'.tr(),
      startingPrice: 16000.00,
      minDecrement: 100.00,
      minParticipants: 3,
      signupCount: 12,
      bidCount: 35,
    ),
    AuctionModel(
      id: 2,
      title: 'auction.demo_title_2'.tr(),
      status: 'BIDDING',
      bidderCount: 5,
      currentLowest: 8200.00,
      quantity: '100${'auction.demo_unit_ton'.tr()}',
      targetPrice: 9500.00,
      description: 'auction.demo_desc_2'.tr(),
      startTime: DateTime.now().subtract(const Duration(hours: 3)),
      endTime: DateTime.now().add(const Duration(hours: 45)),
      tags: ['auction.demo_tag_plastic'.tr(), 'auction.demo_tag_pe'.tr()],
      creatorId: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      auctionNo: 'AUC-2026-0002',
      productName: 'auction.demo_product_2'.tr(),
      productCategory: 'auction.demo_category_chemical'.tr(),
      specification: 'auction.demo_spec_2'.tr(),
      unit: 'auction.demo_unit_ton'.tr(),
      startingPrice: 10000.00,
      minDecrement: 50.00,
      minParticipants: 3,
      signupCount: 8,
      bidCount: 22,
    ),
    AuctionModel(
      id: 3,
      title: 'auction.demo_title_3'.tr(),
      status: 'PUBLISHED',
      bidderCount: 0,
      currentLowest: null,
      quantity: '200${'auction.demo_unit_set'.tr()}',
      targetPrice: 2800.00,
      description: 'auction.demo_desc_3'.tr(),
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 5)),
      tags: ['auction.demo_tag_furniture'.tr(), 'auction.demo_tag_desk_chair'.tr()],
      creatorId: 3,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      auctionNo: 'AUC-2026-0003',
      productName: 'auction.demo_product_3'.tr(),
      productCategory: 'auction.demo_category_furniture'.tr(),
      specification: 'auction.demo_spec_3'.tr(),
      unit: 'auction.demo_unit_set'.tr(),
      startingPrice: 3500.00,
      minDecrement: 20.00,
      minParticipants: 5,
      signupCount: 3,
      bidCount: 0,
    ),
    AuctionModel(
      id: 4,
      title: 'auction.demo_title_4'.tr(),
      status: 'PUBLISHED',
      bidderCount: 0,
      currentLowest: null,
      quantity: '10000${'auction.demo_unit_pcs'.tr()}',
      targetPrice: 3.50,
      description: 'auction.demo_desc_4'.tr(),
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 4)),
      tags: ['auction.demo_tag_electronics'.tr(), 'auction.demo_tag_mcu'.tr()],
      creatorId: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      auctionNo: 'AUC-2026-0004',
      productName: 'STM32F103C8T6',
      productCategory: 'auction.demo_category_electronics'.tr(),
      specification: 'auction.demo_spec_4'.tr(),
      unit: 'auction.demo_unit_pcs'.tr(),
      startingPrice: 5.00,
      minDecrement: 0.10,
      minParticipants: 3,
      signupCount: 6,
      bidCount: 0,
    ),
    AuctionModel(
      id: 5,
      title: 'auction.demo_title_5'.tr(),
      status: 'CLOSED',
      bidderCount: 6,
      currentLowest: 4.20,
      quantity: '50000${'auction.demo_unit_pcs'.tr()}',
      targetPrice: 5.50,
      description: 'auction.demo_desc_5'.tr(),
      startTime: DateTime.now().subtract(const Duration(days: 5)),
      endTime: DateTime.now().subtract(const Duration(days: 2)),
      tags: ['auction.demo_tag_packaging'.tr(), 'auction.demo_tag_carton'.tr()],
      creatorId: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      auctionNo: 'AUC-2026-0005',
      productName: 'auction.demo_product_5'.tr(),
      productCategory: 'auction.demo_category_packaging'.tr(),
      specification: 'auction.demo_spec_5'.tr(),
      unit: 'auction.demo_unit_pcs'.tr(),
      startingPrice: 6.00,
      minDecrement: 0.05,
      minParticipants: 3,
      signupCount: 10,
      bidCount: 48,
      winnerId: 4,
      winnerName: 'auction.demo_winner_1'.tr(),
    ),
    AuctionModel(
      id: 6,
      title: 'auction.demo_title_6'.tr(),
      status: 'CLOSED',
      bidderCount: 4,
      currentLowest: 38.50,
      quantity: '2000${'auction.demo_unit_barrel'.tr()}',
      targetPrice: 45.00,
      description: 'auction.demo_desc_6'.tr(),
      startTime: DateTime.now().subtract(const Duration(days: 10)),
      endTime: DateTime.now().subtract(const Duration(days: 7)),
      tags: ['auction.demo_tag_industrial'.tr(), 'auction.demo_tag_lubricant'.tr()],
      creatorId: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      auctionNo: 'AUC-2026-0006',
      productName: 'auction.demo_product_6'.tr(),
      productCategory: 'auction.demo_category_industrial'.tr(),
      specification: 'auction.demo_spec_6'.tr(),
      unit: 'auction.demo_unit_barrel'.tr(),
      startingPrice: 48.00,
      minDecrement: 0.50,
      minParticipants: 3,
      signupCount: 7,
      bidCount: 31,
      winnerId: 5,
      winnerName: 'auction.demo_winner_2'.tr(),
    ),
  ];

  static List<BidModel> get _mockBids => [
    BidModel(
      id: 1,
      auctionId: 1,
      supplierId: 4,
      supplierName: 'auction.demo_bidder_1'.tr(),
      supplierCompany: 'auction.demo_company_1'.tr(),
      price: 12500,
      bidSequence: 1,
      isLowest: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    BidModel(
      id: 2,
      auctionId: 1,
      supplierId: 5,
      supplierName: 'auction.demo_bidder_2'.tr(),
      supplierCompany: 'auction.demo_company_2'.tr(),
      price: 13200,
      bidSequence: 2,
      isLowest: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BidModel(
      id: 3,
      auctionId: 1,
      supplierId: 6,
      supplierName: 'auction.demo_bidder_3'.tr(),
      supplierCompany: 'auction.demo_company_3'.tr(),
      price: 13800,
      bidSequence: 3,
      isLowest: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BidModel(
      id: 4,
      auctionId: 1,
      supplierId: 7,
      supplierName: 'auction.demo_bidder_4'.tr(),
      supplierCompany: 'auction.demo_company_4'.tr(),
      price: 14000,
      bidSequence: 4,
      isLowest: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  PageResult<AuctionModel> _getMockAuctions({
    String? status,
    String? keyword,
    int page = 0,
  }) {
    var filtered = List<AuctionModel>.from(_mockAuctions);
    if (status != null) {
      filtered = filtered.where((a) => a.status == status).toList();
    }
    if (keyword != null && keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      filtered = filtered
          .where(
            (a) =>
                a.title.toLowerCase().contains(kw) ||
                (a.productCategory?.toLowerCase().contains(kw) ?? false),
          )
          .toList();
    }
    return PageResult(
      content: filtered,
      totalElements: filtered.length,
      totalPages: 1,
      pageNumber: page,
      pageSize: 10,
    );
  }

  /// Fast timeout (fall back to Mock within 5 seconds when backend is unavailable)
  static const _fastTimeout = Duration(seconds: 5);

  // ============ API methods (with Mock fallback) ============

  /// Get public auction list: GET /api/v1/auction/list
  Future<PageResult<AuctionModel>> getAuctions({
    String? status,
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (status != null) params['status'] = status;
      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
      final response = await _dio
          .get(ApiConstants.auctionList, queryParameters: params)
          .timeout(_fastTimeout);
      return _parsePageResult(response.data);
    } catch (_) {
      return _getMockAuctions(status: status, keyword: keyword, page: page);
    }
  }

  /// Get home auctions: GET /api/v1/auction/home
  Future<PageResult<AuctionModel>> getHomeAuctions({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio
          .get(
            ApiConstants.auctionHome,
            queryParameters: {'page': page, 'size': size},
          )
          .timeout(_fastTimeout);
      return _parsePageResult(response.data);
    } catch (_) {
      final active = _mockAuctions.where((a) => a.status == 'BIDDING').toList();
      return PageResult(
        content: active,
        totalElements: active.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: size,
      );
    }
  }

  /// Get auction detail: GET /api/v1/auction/{id}
  Future<AuctionModel> getAuctionDetail(int id) async {
    try {
      final response = await _dio
          .get('${ApiConstants.auctionBase}/$id')
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return AuctionModel.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return _mockAuctions.firstWhere(
        (a) => a.id == id,
        orElse: () => _mockAuctions.first,
      );
    }
  }

  /// Create auction: POST /api/v1/auction/create
  Future<AuctionModel> createAuction(Map<String, dynamic> auctionData) async {
    try {
      final response = await _dio
          .post(ApiConstants.auctionCreate, data: auctionData)
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return AuctionModel.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      final newAuction = AuctionModel.fromJson({
        ...auctionData,
        'id': _mockAuctions.length + 1,
        'status': 'DRAFT',
        'auctionNo':
            'AUC-2026-${(_mockAuctions.length + 1).toString().padLeft(4, '0')}',
        'createdAt': DateTime.now().toIso8601String(),
      });
      return newAuction;
    }
  }

  /// Supplier bid: POST /api/v1/auction/bid
  Future<void> placeBid(int auctionId, double price) async {
    try {
      await _dio
          .post(
            ApiConstants.auctionBid,
            data: {'auctionId': auctionId, 'price': price},
          )
          .timeout(_fastTimeout);
    } catch (_) {
      // Mock: bid success
    }
  }

  /// Supplier signup: POST /api/v1/auction/{id}/signup
  Future<void> signup(int auctionId) async {
    try {
      await _dio
          .post('${ApiConstants.auctionBase}/$auctionId/signup')
          .timeout(_fastTimeout);
    } catch (_) {
      // Mock: signup success
    }
  }

  /// Get my auctions: GET /api/v1/auction/my
  Future<PageResult<AuctionModel>> getMyAuctions({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio
          .get(
            ApiConstants.auctionMy,
            queryParameters: {'page': page, 'size': size},
          )
          .timeout(_fastTimeout);
      return _parsePageResult(response.data);
    } catch (_) {
      final my = _mockAuctions.where((a) => a.creatorId == 2).toList();
      return PageResult(
        content: my,
        totalElements: my.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: size,
      );
    }
  }

  /// Submit for review: POST /api/v1/auction/{id}/publish
  Future<void> publishAuction(int auctionId) async {
    try {
      await _dio
          .post('${ApiConstants.auctionBase}/$auctionId/publish')
          .timeout(_fastTimeout);
    } catch (_) {}
  }

  /// Cancel auction: POST /api/v1/auction/{id}/cancel
  Future<void> cancelAuction(int auctionId) async {
    try {
      await _dio
          .post('${ApiConstants.auctionBase}/$auctionId/cancel')
          .timeout(_fastTimeout);
    } catch (_) {}
  }

  /// Buyer confirm result: POST /api/v1/auction/{id}/buyer-confirm
  Future<void> buyerConfirm(int auctionId) async {
    try {
      await _dio
          .post('${ApiConstants.auctionBase}/$auctionId/buyer-confirm')
          .timeout(_fastTimeout);
    } catch (_) {}
  }

  /// Get bid records: GET /api/v1/auction/{id}/bids
  Future<List<BidModel>> getBids(int auctionId) async {
    try {
      final response = await _dio
          .get(ApiConstants.auctionBids(auctionId))
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      if (body is List) {
        return body
            .map((e) => BidModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return _mockBids.where((b) => b.auctionId == auctionId).toList();
    }
  }

  /// Get my participation status: GET /api/v1/auction/{id}/my-status
  Future<Map<String, dynamic>> getMyStatus(int auctionId) async {
    try {
      final response = await _dio
          .get(ApiConstants.auctionMyStatus(auctionId))
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return body is Map<String, dynamic> ? body : {};
    } catch (_) {
      return {'signedUp': false, 'depositPaid': false};
    }
  }

  /// Get my ranking: GET /api/v1/auction/{id}/my-ranking
  Future<Map<String, dynamic>> getMyRanking(int auctionId) async {
    try {
      final response = await _dio
          .get(ApiConstants.auctionMyRanking(auctionId))
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return body is Map<String, dynamic> ? body : {};
    } catch (_) {
      return {};
    }
  }

  /// Supplier confirm winning bid: POST /api/v1/auction/{id}/supplier-confirm
  Future<void> supplierConfirm(int auctionId) async {
    try {
      await _dio
          .post(ApiConstants.auctionSupplierConfirm(auctionId))
          .timeout(_fastTimeout);
    } catch (_) {}
  }

  /// Re-auction: POST /api/v1/auction/{id}/re-auction
  Future<void> reAuction(int auctionId) async {
    try {
      await _dio
          .post(ApiConstants.auctionReAuction(auctionId))
          .timeout(_fastTimeout);
    } catch (_) {}
  }

  // ============ Deposit related ============

  /// Check deposit status: GET /api/v1/auction/deposit/check
  Future<DepositInfo> checkDeposit(int auctionId) async {
    try {
      final response = await _dio
          .get(
            ApiConstants.depositCheck,
            queryParameters: {'auctionId': auctionId},
          )
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return DepositInfo.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return DepositInfo.unpaid();
    }
  }

  /// Supplier pay deposit: POST /api/v1/auction/deposit/supplier/pay
  Future<DepositInfo> supplierPayDeposit(
    int auctionId, {
    String? voucherUrl,
  }) async {
    try {
      final data = <String, dynamic>{'auctionId': auctionId};
      if (voucherUrl != null) data['voucherUrl'] = voucherUrl;
      final response = await _dio
          .post(ApiConstants.depositSupplierPay, data: data)
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return DepositInfo.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return DepositInfo.unpaid();
    }
  }

  /// Buyer pay deposit: POST /api/v1/auction/deposit/buyer/pay
  Future<DepositInfo> buyerPayDeposit(
    int auctionId, {
    String? voucherUrl,
  }) async {
    try {
      final data = <String, dynamic>{'auctionId': auctionId};
      if (voucherUrl != null) data['voucherUrl'] = voucherUrl;
      final response = await _dio
          .post(ApiConstants.depositBuyerPay, data: data)
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      return DepositInfo.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return DepositInfo.unpaid();
    }
  }

  /// Get my deposit vouchers: GET /api/v1/auction/deposit/vouchers/my
  Future<List<Map<String, dynamic>>> getMyDepositVouchers(int auctionId) async {
    try {
      final response = await _dio
          .get(
            ApiConstants.depositVouchersMy,
            queryParameters: {'auctionId': auctionId},
          )
          .timeout(_fastTimeout);
      final body = _unwrapData(response.data);
      if (body is List) {
        return body.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  dynamic _unwrapData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<AuctionModel> _parsePageResult(dynamic data) {
    final body = _unwrapData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (json) => AuctionModel.fromJson(json));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => AuctionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: body.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: body.length,
      );
    }
    return const PageResult(
      content: [],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      pageSize: 10,
    );
  }
}
