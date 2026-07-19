import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/auction_model.dart';
import '../providers/auction_provider.dart';
import '../providers/auction_websocket_provider.dart';

/// 竞价详情页 - 匹配网站 auction-detail.html
/// 状态机 UI: 报名→押金→竞价→确认→完成
class AuctionDetailScreen extends ConsumerStatefulWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(auctionDetailProvider(widget.auctionId).notifier).loadDetail();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionDetailProvider(widget.auctionId));
    final notifier = ref.read(auctionDetailProvider(widget.auctionId).notifier);

    // 监听 WebSocket 消息
    ref.listen(auctionWsProvider(widget.auctionId), (prev, next) {
      next.whenData((msg) {
        switch (msg.type) {
          case AuctionMessageType.bidUpdate:
            final bid = msg.bid;
            if (bid != null) notifier.onWsBidUpdate(bid);
            break;
          case AuctionMessageType.statusUpdate:
            final s = msg.newStatus;
            if (s != null) notifier.onWsStatusUpdate(s);
            break;
          case AuctionMessageType.extension:
            final t = msg.newEndTime;
            if (t != null) notifier.onWsExtension(t);
            break;
          case AuctionMessageType.unknown:
            break;
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('auction.detail_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => notifier.loadDetail(),
          ),
        ],
      ),
      body: state.isLoading && state.auction == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.auction == null
          ? _buildError(state.error!, notifier)
          : state.auction != null
          ? _buildContent(state, notifier)
          : const SizedBox.shrink(),
      bottomNavigationBar: _buildBottomBar(state, notifier),
    );
  }

  Widget _buildError(String error, AuctionDetailNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: 12),
          Text(
            'auction.load_failed'.tr(),
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          TextButton(
            onPressed: () => notifier.loadDetail(),
            child: Text(
              'common.retry'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AuctionDetailState state,
    AuctionDetailNotifier notifier,
  ) {
    final a = state.auction!;
    return RefreshIndicator(
      onRefresh: () => notifier.loadDetail(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(a),
            const SizedBox(height: 12),
            if (a.isActive) _buildCountdownCard(a),
            if (a.isActive) const SizedBox(height: 12),
            _buildPriceMetaCard(a),
            const SizedBox(height: 12),
            _buildAuctionInfoCard(a),
            const SizedBox(height: 12),
            if (a.isSignup || a.isActive) _buildDepositCard(state, notifier),
            if (a.isSignup || a.isActive) const SizedBox(height: 12),
            if (state.myRank != null) _buildMyRankingCard(state),
            if (state.myRank != null) const SizedBox(height: 12),
            _buildBidHistoryCard(state),
            if (a.isConfirming) const SizedBox(height: 12),
            if (a.isConfirming) _buildConfirmCard(a, state, notifier),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============ 头部卡片 ============
  Widget _buildHeaderCard(AuctionModel a) {
    final statusColor = _getStatusColor(a.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.featureYellow.withValues(alpha: 0.12),
            AppColors.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: AppColors.featureYellow.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(a.title, style: AppTextStyles.headingL)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  a.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (a.auctionNo != null) ...[
            const SizedBox(height: 6),
            Text(
              'auction.auction_no'.tr(args: [a.auctionNo!]),
              style: AppTextStyles.caption,
            ),
          ],
          if (a.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: a.tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ============ 倒计时卡片 ============
  Widget _buildCountdownCard(AuctionModel a) {
    if (a.endTime == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final diff = a.endTime!.difference(now);
    final isEnded = diff.isNegative;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        children: [
          Text(
            isEnded
                ? 'auction.auction_ended'.tr()
                : 'auction.time_remaining'.tr(),
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (!isEnded)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _countdownUnit(diff.inHours.toString().padLeft(2, '0')),
                _countdownSep(),
                _countdownUnit(
                  (diff.inMinutes % 60).toString().padLeft(2, '0'),
                ),
                _countdownSep(),
                _countdownUnit(
                  (diff.inSeconds % 60).toString().padLeft(2, '0'),
                ),
              ],
            ),
          if (a.currentExtensions > 0) ...[
            const SizedBox(height: 8),
            Text(
              'auction.extension_count'.tr(
                args: ['${a.currentExtensions}', '${a.maxExtensions}'],
              ),
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countdownUnit(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        val,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textOnPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _countdownSep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ============ 价格指标卡片 ============
  Widget _buildPriceMetaCard(AuctionModel a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _metaItem(
            'auction.current_lowest_price'.tr(),
            a.currentLowest != null
                ? '\u00a5${a.currentLowest!.toStringAsFixed(2)}'
                : 'auction.no_bid_yet'.tr(),
            a.currentLowest != null
                ? AppColors.textPrice
                : AppColors.textPlaceholder,
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          _metaItem(
            'auction.max_price'.tr(),
            '\u00a5${a.effectiveStartingPrice.toStringAsFixed(2)}',
            AppColors.textTitle,
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          _metaItem(
            'auction.signup_bids'.tr(),
            '${a.signupCount}${'auction.bidder_unit'.tr()}/${a.bidCount}${'auction.bid_times_unit'.tr()}',
            AppColors.featureTeal,
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ============ 竞价信息卡片 ============
  Widget _buildAuctionInfoCard(AuctionModel a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('auction.auction_info'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          if (a.productName != null)
            _infoRow('auction.product_name'.tr(), a.productName!),
          if (a.productCategory != null)
            _infoRow('auction.product_category'.tr(), a.productCategory!),
          _infoRow(
            'auction.purchase_quantity'.tr(),
            '${a.quantity} ${a.unit ?? ''}',
          ),
          _infoRow(
            'auction.max_price'.tr(),
            '\u00a5${a.effectiveStartingPrice.toStringAsFixed(2)}',
          ),
          if (a.minDecrement != null)
            _infoRow(
              'auction.min_decrement'.tr(),
              '\u00a5${a.minDecrement!.toStringAsFixed(2)}',
            ),
          if (a.startTime != null)
            _infoRow('auction.bid_start'.tr(), _formatDate(a.startTime!)),
          if (a.endTime != null)
            _infoRow('auction.bid_end'.tr(), _formatDate(a.endTime!)),
          if (a.signupStartTime != null)
            _infoRow(
              'auction.signup_time'.tr(),
              '${_formatDate(a.signupStartTime!)} ~ ${a.signupEndTime != null ? _formatDate(a.signupEndTime!) : ''}',
            ),
          _infoRow('auction.min_suppliers'.tr(), '${a.minParticipants}${'auction.bidder_unit'.tr()}'),
          if (a.deliveryAddress != null && a.deliveryAddress!.isNotEmpty)
            _infoRow('auction.delivery_address'.tr(), a.deliveryAddress!),
          if (a.paymentTerms != null && a.paymentTerms!.isNotEmpty)
            _infoRow('auction.payment_terms'.tr(), a.paymentTerms!),
          if (a.specification != null && a.specification!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            Text(
              'auction.product_spec'.tr(),
              style: AppTextStyles.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.specification!,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (a.description != null && a.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            Text(
              'auction.requirement_desc'.tr(),
              style: AppTextStyles.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.description!,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ 押金卡片 ============
  Widget _buildDepositCard(
    AuctionDetailState state,
    AuctionDetailNotifier notifier,
  ) {
    final deposit = state.deposit;
    final isPaid = state.isDepositPaid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'auction.deposit_status'.tr(),
                style: AppTextStyles.headingS,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? 'common.paid'.tr() : 'common.not_paid'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaid ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppRadius.smBorder,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'auction.deposit_amount'.tr(),
                      style: AppTextStyles.bodyS,
                    ),
                    Text(
                      '\$${deposit?.amount.toStringAsFixed(2) ?? '50.00'} USD',
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => notifier.payDeposit(isSupplier: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'auction.pay_deposit'.tr(),
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ 我的排名卡片 ============
  Widget _buildMyRankingCard(AuctionDetailState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${state.myRank}',
                style: AppTextStyles.headingL.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('auction.my_ranking'.tr(), style: AppTextStyles.bodyS),
                if (state.myLowestBid != null)
                  Text(
                    'auction.my_lowest_bid'.tr(args: [state.myLowestBid!.toStringAsFixed(2)]),
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ 出价记录卡片 ============
  Widget _buildBidHistoryCard(AuctionDetailState state) {
    final bids = state.bids;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('auction.bid_history'.tr(), style: AppTextStyles.headingS),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${bids.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bids.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.gavel_rounded,
                      size: 40,
                      color: AppColors.textPlaceholder.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'auction.no_bids'.tr(),
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(bids.length, (i) {
              final bid = bids[i];
              final isLowest = bid.isLowest == true || i == 0;
              final isWinner = bid.isWinner == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isWinner
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : isLowest
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.pageBg,
                  borderRadius: AppRadius.mdBorder,
                  border: isWinner
                      ? Border.all(color: AppColors.primary, width: 2)
                      : isLowest
                      ? Border(
                          left: BorderSide(color: AppColors.primary, width: 3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    if (isWinner)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '${bid.bidSequence ?? i + 1}',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bid.supplierCompany ?? bid.supplierName,
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTitle,
                            ),
                          ),
                          if (bid.createdAt != null)
                            Text(
                              _formatDate(bid.createdAt!),
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\u00a5${bid.price.toStringAsFixed(2)}',
                          style: isLowest
                              ? AppTextStyles.price
                              : AppTextStyles.bodyL.copyWith(
                                  color: AppColors.textTitle,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                        if (isLowest)
                          Text(
                            'auction.lowest_price'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ============ 确认卡片 (竞价结束待确认) ============
  Widget _buildConfirmCard(
    AuctionModel a,
    AuctionDetailState state,
    AuctionDetailNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'auction.pending_confirm'.tr(),
                style: AppTextStyles.headingS.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (a.winnerName != null)
            _infoRow('auction.winner_supplier'.tr(), a.winnerName!),
          if (a.confirmDeadline != null)
            _infoRow(
              'auction.confirm_deadline'.tr(),
              _formatDate(a.confirmDeadline!),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (a.buyerConfirmed != true)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => notifier.buyerConfirm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'auction.buyer_confirm'.tr(),
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              if (a.buyerConfirmed != true && a.supplierConfirmed != true)
                const SizedBox(width: 12),
              if (a.supplierConfirmed != true)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => notifier.supplierConfirm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.featureTeal,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'auction.supplier_confirm'.tr(),
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 底部操作栏 ============
  Widget? _buildBottomBar(
    AuctionDetailState state,
    AuctionDetailNotifier notifier,
  ) {
    final a = state.auction;
    if (a == null) return null;

    // 报名阶段
    if (a.isSignup && !state.isSignedUp) {
      return _bottomBarContainer(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => notifier.signup(),
            icon: const Icon(Icons.how_to_reg_rounded, size: 20),
            label: Text(
              'auction.signup_now'.tr(),
              style: AppTextStyles.button.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.featureYellow,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    // 竞价阶段
    if (a.isActive) {
      return _bottomBarContainer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'auction.current_lowest_price'.tr(),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.currentLowest != null
                        ? '\u00a5${a.currentLowest!.toStringAsFixed(2)}'
                        : 'auction.no_bid_yet'.tr(),
                    style: a.currentLowest != null
                        ? AppTextStyles.priceL
                        : AppTextStyles.bodyM.copyWith(
                            color: AppColors.textPlaceholder,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: state.isBidding
                    ? null
                    : () => _showBidDialog(state, notifier),
                icon: const Icon(Icons.gavel_rounded, size: 18),
                label: Text(
                  state.isBidding
                      ? 'auction.bidding_progress'.tr()
                      : 'auction.bid_now'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return null;
  }

  Widget _bottomBarContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: child,
    );
  }

  // ============ 出价弹窗 ============
  void _showBidDialog(
    AuctionDetailState state,
    AuctionDetailNotifier notifier,
  ) {
    final priceCtrl = TextEditingController();
    final a = state.auction!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('auction.submit_bid'.tr(), style: AppTextStyles.headingM),
              const SizedBox(height: 4),
              Text(
                a.title,
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // 价格信息条
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Row(
                  children: [
                    _bidInfoItem(
                      'auction.max_price'.tr(),
                      '\u00a5${a.effectiveStartingPrice.toStringAsFixed(2)}',
                      AppColors.textTitle,
                    ),
                    Container(width: 1, height: 30, color: AppColors.divider),
                    _bidInfoItem(
                      'auction.current_lowest'.tr(),
                      a.currentLowest != null
                          ? '\u00a5${a.currentLowest!.toStringAsFixed(2)}'
                          : '--',
                      AppColors.textPrice,
                    ),
                    Container(width: 1, height: 30, color: AppColors.divider),
                    _bidInfoItem(
                      'auction.bid_count'.tr(),
                      '${state.bids.length}${'auction.bid_times_unit'.tr()}',
                      AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTitle,
                ),
                decoration: InputDecoration(
                  prefixText: '\u00a5 ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  hintText: 'auction.bid_price_hint'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 20,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: AppColors.searchBarBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (a.currentLowest != null)
                Text(
                  'auction.bid_must_lower'.tr(args: [a.currentLowest!.toStringAsFixed(2)]),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              if (a.minDecrement != null)
                Text(
                  'auction.bid_min_decrement'.tr(args: [a.minDecrement!.toStringAsFixed(2)]),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _BidSubmitButton(
                  priceCtrl: priceCtrl,
                  auction: a,
                  onSubmit: (price) async {
                    final success = await notifier.placeBid(price);
                    return success;
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bidInfoItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
      case 'BIDDING':
        return AppColors.success;
      case 'SIGNUP':
      case 'APPROVED':
        return AppColors.featureYellow;
      case 'CONFIRMING':
        return AppColors.warning;
      case 'PUBLISHED':
      case 'PENDING':
        return AppColors.info;
      case 'COMPLETED':
      case 'CONFIRMED':
        return AppColors.primary;
      case 'FAILED':
      case 'CANCELLED':
      case 'VOIDED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 出价提交按钮
class _BidSubmitButton extends StatefulWidget {
  final TextEditingController priceCtrl;
  final AuctionModel auction;
  final Future<bool> Function(double price) onSubmit;

  const _BidSubmitButton({
    required this.priceCtrl,
    required this.auction,
    required this.onSubmit,
  });

  @override
  State<_BidSubmitButton> createState() => _BidSubmitButtonState();
}

class _BidSubmitButtonState extends State<_BidSubmitButton> {
  bool _submitting = false;

  Future<void> _handleSubmit() async {
    final price = double.tryParse(widget.priceCtrl.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auction.invalid_bid_amount'.tr())));
      return;
    }
    // 不能高于最高限价
    if (price > widget.auction.effectiveStartingPrice) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auction.bid_exceeds_max'.tr())));
      return;
    }
    // 需低于当前最低价
    if (widget.auction.currentLowest != null &&
        price >= widget.auction.currentLowest!) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auction.bid_below_current'.tr())));
      return;
    }
    // 最小降幅
    if (widget.auction.minDecrement != null &&
        widget.auction.currentLowest != null) {
      final minPrice =
          widget.auction.currentLowest! - widget.auction.minDecrement!;
      if (price > minPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'auction.bid_decrement_fail'.tr(args: [widget.auction.minDecrement!.toStringAsFixed(2)]),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final success = await widget.onSubmit(price);
      if (mounted && success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auction.bid_success'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auction.bid_failed'.tr(args: ['$e']))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _submitting ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _submitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
              ),
            )
          : Text(
              'auction.confirm_bid'.tr(),
              style: AppTextStyles.bodyL.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textOnPrimary,
              ),
            ),
    );
  }
}
