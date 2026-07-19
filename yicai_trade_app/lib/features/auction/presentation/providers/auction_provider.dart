import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/auction_repository.dart';
import '../../data/models/auction_model.dart';

// ============ Repository Provider ============
final auctionRepositoryProvider = Provider<AuctionRepository>((ref) {
  return AuctionRepository(ref.read(dioProvider));
});

// ============ 竞价列表状态 ============
class AuctionListState {
  final List<AuctionModel> auctions;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String currentTab;

  const AuctionListState({
    this.auctions = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
    this.currentTab = 'ALL',
  });

  AuctionListState copyWith({
    List<AuctionModel>? auctions,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? currentTab,
  }) {
    return AuctionListState(
      auctions: auctions ?? this.auctions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      currentTab: currentTab ?? this.currentTab,
    );
  }
}

final auctionListProvider =
    StateNotifierProvider<AuctionListNotifier, AuctionListState>((ref) {
      return AuctionListNotifier(ref.read(auctionRepositoryProvider));
    });

class AuctionListNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;

  AuctionListNotifier(this._repository) : super(const AuctionListState());

  Future<void> loadAuctions({String? status, String? keyword}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getAuctions(
        status: status,
        keyword: keyword,
        page: 0,
      );
      state = state.copyWith(
        auctions: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final apiStatus = AuctionModel.tabToApiStatus(state.currentTab);
      final result = await _repository.getAuctions(
        status: apiStatus,
        page: nextPage,
      );
      state = state.copyWith(
        auctions: [...state.auctions, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void switchTab(String tab) {
    state = state.copyWith(currentTab: tab, auctions: [], currentPage: 0);
    final apiStatus = AuctionModel.tabToApiStatus(tab);
    loadAuctions(status: apiStatus);
  }

  Future<void> refresh() =>
      loadAuctions(status: AuctionModel.tabToApiStatus(state.currentTab));
}

// ============ 竞价详情状态 ============
class AuctionDetailState {
  final AuctionModel? auction;
  final List<BidModel> bids;
  final DepositInfo? deposit;
  final Map<String, dynamic> myStatus;
  final Map<String, dynamic> myRanking;
  final bool isLoading;
  final String? error;
  final bool isBidding;

  const AuctionDetailState({
    this.auction,
    this.bids = const [],
    this.deposit,
    this.myStatus = const {},
    this.myRanking = const {},
    this.isLoading = false,
    this.error,
    this.isBidding = false,
  });

  bool get isSignedUp => myStatus['signedUp'] == true;
  bool get isDepositPaid =>
      deposit?.isPaid ?? (myStatus['depositPaid'] == true);
  int? get myRank => myRanking['rank'] as int?;
  double? get myLowestBid {
    final v = myRanking['lowestBid'] ?? myRanking['myLowestPrice'];
    return v != null ? (v as num).toDouble() : null;
  }

  AuctionDetailState copyWith({
    AuctionModel? auction,
    List<BidModel>? bids,
    DepositInfo? deposit,
    Map<String, dynamic>? myStatus,
    Map<String, dynamic>? myRanking,
    bool? isLoading,
    String? error,
    bool? isBidding,
  }) {
    return AuctionDetailState(
      auction: auction ?? this.auction,
      bids: bids ?? this.bids,
      deposit: deposit ?? this.deposit,
      myStatus: myStatus ?? this.myStatus,
      myRanking: myRanking ?? this.myRanking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isBidding: isBidding ?? this.isBidding,
    );
  }
}

final auctionDetailProvider =
    StateNotifierProvider.family<
      AuctionDetailNotifier,
      AuctionDetailState,
      int
    >((ref, auctionId) {
      return AuctionDetailNotifier(
        ref.read(auctionRepositoryProvider),
        auctionId,
      );
    });

class AuctionDetailNotifier extends StateNotifier<AuctionDetailState> {
  final AuctionRepository _repository;
  final int _auctionId;

  AuctionDetailNotifier(this._repository, this._auctionId)
    : super(const AuctionDetailState());

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getAuctionDetail(_auctionId),
        _repository.getBids(_auctionId),
        _repository.checkDeposit(_auctionId),
        _repository.getMyStatus(_auctionId),
        _repository.getMyRanking(_auctionId),
      ]);
      state = state.copyWith(
        auction: results[0] as AuctionModel,
        bids: results[1] as List<BidModel>,
        deposit: results[2] as DepositInfo,
        myStatus: results[3] as Map<String, dynamic>,
        myRanking: results[4] as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signup() async {
    try {
      await _repository.signup(_auctionId);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(error: '${'auction.signup_failed'.tr()}: $e');
    }
  }

  Future<bool> placeBid(double price) async {
    state = state.copyWith(isBidding: true, error: null);
    try {
      await _repository.placeBid(_auctionId, price);
      state = state.copyWith(isBidding: false);
      await _refreshBidsAndRanking();
      return true;
    } catch (e) {
      state = state.copyWith(
        isBidding: false,
        error: 'auction.bid_failed'.tr(args: ['$e']),
      );
      return false;
    }
  }

  Future<void> buyerConfirm() async {
    try {
      await _repository.buyerConfirm(_auctionId);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(error: '${'auction.confirm_failed'.tr()}: $e');
    }
  }

  Future<void> supplierConfirm() async {
    try {
      await _repository.supplierConfirm(_auctionId);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(error: '${'auction.confirm_failed'.tr()}: $e');
    }
  }

  Future<void> payDeposit({
    required bool isSupplier,
    String? voucherUrl,
  }) async {
    try {
      DepositInfo deposit;
      if (isSupplier) {
        deposit = await _repository.supplierPayDeposit(
          _auctionId,
          voucherUrl: voucherUrl,
        );
      } else {
        deposit = await _repository.buyerPayDeposit(
          _auctionId,
          voucherUrl: voucherUrl,
        );
      }
      state = state.copyWith(deposit: deposit);
    } catch (e) {
      state = state.copyWith(error: '${'auction.deposit_failed'.tr()}: $e');
    }
  }

  void onWsBidUpdate(BidModel newBid) {
    final updatedBids = [newBid, ...state.bids];
    state = state.copyWith(bids: updatedBids);
  }

  void onWsStatusUpdate(String newStatus) {
    if (state.auction != null) {
      final updated = AuctionModel.fromJson({
        ...state.auction!.toJson(),
        'id': state.auction!.id,
        'status': newStatus,
      });
      state = state.copyWith(auction: updated);
    }
  }

  void onWsExtension(DateTime newEndTime) {
    if (state.auction != null) {
      final updated = AuctionModel.fromJson({
        ...state.auction!.toJson(),
        'id': state.auction!.id,
        'endTime': newEndTime.toIso8601String(),
        'currentExtensions': state.auction!.currentExtensions + 1,
      });
      state = state.copyWith(auction: updated);
    }
  }

  Future<void> _refreshBidsAndRanking() async {
    try {
      final results = await Future.wait([
        _repository.getBids(_auctionId),
        _repository.getMyRanking(_auctionId),
      ]);
      state = state.copyWith(
        bids: results[0] as List<BidModel>,
        myRanking: results[1] as Map<String, dynamic>,
      );
    } catch (_) {}
  }
}

// ============ 创建竞价状态 ============
class CreateAuctionState {
  final String title;
  final String productName;
  final String productCategory;
  final String specification;
  final String quantity;
  final String unit;
  final double? targetPrice;
  final double? startingPrice;
  final double? minDecrement;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? signupStartTime;
  final DateTime? signupEndTime;
  final int minParticipants;
  final bool showRanking;
  final bool showLowestPrice;
  final String deliveryAddress;
  final String requiredDeliveryDate;
  final String paymentTerms;
  final String remark;
  final String description;
  final bool isSubmitting;
  final String? error;

  const CreateAuctionState({
    this.title = '',
    this.productName = '',
    this.productCategory = '',
    this.specification = '',
    this.quantity = '',
    this.unit = 'pcs',
    this.targetPrice,
    this.startingPrice,
    this.minDecrement,
    this.startTime,
    this.endTime,
    this.signupStartTime,
    this.signupEndTime,
    this.minParticipants = 3,
    this.showRanking = true,
    this.showLowestPrice = true,
    this.deliveryAddress = '',
    this.requiredDeliveryDate = '',
    this.paymentTerms = '',
    this.remark = '',
    this.description = '',
    this.isSubmitting = false,
    this.error,
  });

  bool get isValid =>
      title.isNotEmpty &&
      quantity.isNotEmpty &&
      targetPrice != null &&
      targetPrice! > 0;

  Map<String, dynamic> toJson() => {
    'title': title,
    'productName': productName.isNotEmpty ? productName : title,
    if (productCategory.isNotEmpty) 'productCategory': productCategory,
    if (specification.isNotEmpty) 'specification': specification,
    'quantity': quantity,
    'unit': unit,
    'targetPrice': targetPrice,
    if (startingPrice != null) 'startingPrice': startingPrice,
    if (minDecrement != null) 'minDecrement': minDecrement,
    'description': description,
    if (startTime != null) 'startTime': startTime!.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    if (signupStartTime != null)
      'signupStartTime': signupStartTime!.toIso8601String(),
    if (signupEndTime != null)
      'signupEndTime': signupEndTime!.toIso8601String(),
    'minParticipants': minParticipants,
    'showRanking': showRanking,
    'showLowestPrice': showLowestPrice,
    if (deliveryAddress.isNotEmpty) 'deliveryAddress': deliveryAddress,
    if (requiredDeliveryDate.isNotEmpty)
      'requiredDeliveryDate': requiredDeliveryDate,
    if (paymentTerms.isNotEmpty) 'paymentTerms': paymentTerms,
    if (remark.isNotEmpty) 'remark': remark,
  };

  CreateAuctionState copyWith({
    String? title,
    String? productName,
    String? productCategory,
    String? specification,
    String? quantity,
    String? unit,
    double? targetPrice,
    double? startingPrice,
    double? minDecrement,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? signupStartTime,
    DateTime? signupEndTime,
    int? minParticipants,
    bool? showRanking,
    bool? showLowestPrice,
    String? deliveryAddress,
    String? requiredDeliveryDate,
    String? paymentTerms,
    String? remark,
    String? description,
    bool? isSubmitting,
    String? error,
  }) {
    return CreateAuctionState(
      title: title ?? this.title,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      specification: specification ?? this.specification,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      targetPrice: targetPrice ?? this.targetPrice,
      startingPrice: startingPrice ?? this.startingPrice,
      minDecrement: minDecrement ?? this.minDecrement,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      signupStartTime: signupStartTime ?? this.signupStartTime,
      signupEndTime: signupEndTime ?? this.signupEndTime,
      minParticipants: minParticipants ?? this.minParticipants,
      showRanking: showRanking ?? this.showRanking,
      showLowestPrice: showLowestPrice ?? this.showLowestPrice,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      requiredDeliveryDate: requiredDeliveryDate ?? this.requiredDeliveryDate,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      remark: remark ?? this.remark,
      description: description ?? this.description,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

final createAuctionProvider =
    StateNotifierProvider<CreateAuctionNotifier, CreateAuctionState>((ref) {
      return CreateAuctionNotifier(ref.read(auctionRepositoryProvider));
    });

class CreateAuctionNotifier extends StateNotifier<CreateAuctionState> {
  final AuctionRepository _repository;

  CreateAuctionNotifier(this._repository) : super(const CreateAuctionState());

  void updateField({
    String? title,
    String? productName,
    String? productCategory,
    String? specification,
    String? quantity,
    String? unit,
    double? targetPrice,
    double? startingPrice,
    double? minDecrement,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? signupStartTime,
    DateTime? signupEndTime,
    int? minParticipants,
    bool? showRanking,
    bool? showLowestPrice,
    String? deliveryAddress,
    String? requiredDeliveryDate,
    String? paymentTerms,
    String? remark,
    String? description,
  }) {
    state = state.copyWith(
      title: title,
      productName: productName,
      productCategory: productCategory,
      specification: specification,
      quantity: quantity,
      unit: unit,
      targetPrice: targetPrice,
      startingPrice: startingPrice,
      minDecrement: minDecrement,
      startTime: startTime,
      endTime: endTime,
      signupStartTime: signupStartTime,
      signupEndTime: signupEndTime,
      minParticipants: minParticipants,
      showRanking: showRanking,
      showLowestPrice: showLowestPrice,
      deliveryAddress: deliveryAddress,
      requiredDeliveryDate: requiredDeliveryDate,
      paymentTerms: paymentTerms,
      remark: remark,
      description: description,
    );
  }

  Future<AuctionModel?> submit() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'auction.fill_required'.tr());
      return null;
    }
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final auction = await _repository.createAuction(state.toJson());
      state = const CreateAuctionState();
      return auction;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: '${'auction.create_failed'.tr()}: $e',
      );
      return null;
    }
  }

  void reset() {
    state = const CreateAuctionState();
  }
}
