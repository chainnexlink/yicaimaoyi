import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/wallet_repository.dart';
import '../providers/wallet_provider.dart';

/// 钱包管理页 - 对标网站用户中心零钱管理
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(walletProvider.notifier).loadWallet();
      ref.read(walletProvider.notifier).loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.read(walletProvider.notifier).resetError();
    await ref.read(walletProvider.notifier).loadWallet();
    await ref.read(walletProvider.notifier).loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('wallet.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(WalletState state) {
    // 加载中（首次）
    if (state.isLoading && state.wallet == null && state.error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 错误状态且无缓存数据
    if (state.error != null && state.wallet == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(height: 16),
              Text('common.load_failed'.tr(), style: AppTextStyles.headingS),
              const SizedBox(height: 8),
              Text(
                'common.check_network'.tr(),
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    // 正常展示
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(state.wallet),
            const SizedBox(height: 12),
            _buildStatsCard(state.wallet),
            const SizedBox(height: 16),
            _buildTabSection(state),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WalletInfo? wallet) {
    final balance = wallet?.balance ?? 0;
    final frozen = wallet?.frozenAmount ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        children: [
          Text(
            'wallet.account_balance'.tr(),
            style: AppTextStyles.bodyS.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '\u00a5${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (frozen > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${'wallet.frozen_amount'.tr()}: \u00a5${frozen.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _walletAction('wallet.deposit'.tr(), Icons.add_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _walletAction(
                  'wallet.withdraw'.tr(),
                  Icons.output_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletAction(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(WalletInfo? wallet) {
    final txns = ref.read(walletProvider).transactions;
    final totalIncome = txns
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = txns
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalRebate = txns
        .where((t) => t.type == 'REBATE' || t.type == 'COMMISSION')
        .fold<double>(0, (sum, t) => sum + t.amount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Row(
        children: [
          _statItem('wallet.total_income'.tr(), totalIncome, AppColors.success),
          Container(width: 1, height: 32, color: AppColors.divider),
          _statItem('wallet.total_expense'.tr(), totalExpense, AppColors.error),
          Container(width: 1, height: 32, color: AppColors.divider),
          _statItem('wallet.rebate'.tr(), totalRebate, const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _statItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            '\u00a5${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 区域：交易流水 + 返佣记录
  Widget _buildTabSection(WalletState state) {
    final allTransactions = state.transactions;
    final rebateTransactions = allTransactions
        .where((t) => t.type == 'REBATE' || t.type == 'COMMISSION')
        .toList();

    return Column(
      children: [
        // Tab 栏
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: AppRadius.lgBorder,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.bodyM.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.bodyM,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: AppColors.primary,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text('wallet.transactions'.tr()),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text('wallet.rebate_records'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab 内容 - 使用 AnimatedBuilder 监听 tab 切换
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index == 0) {
              return _buildTransactionList(allTransactions);
            } else {
              return _buildRebateList(rebateTransactions);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<WalletTransaction> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'wallet.no_transactions'.tr(),
        subtitle: 'wallet.no_transactions_desc'.tr(),
      );
    }
    return Column(
      children: transactions.map((txn) => _buildTransactionItem(txn)).toList(),
    );
  }

  Widget _buildRebateList(List<WalletTransaction> rebateTransactions) {
    if (rebateTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.card_giftcard_outlined,
        title: 'wallet.no_rebate'.tr(),
        subtitle: 'wallet.no_rebate_desc'.tr(),
      );
    }
    return Column(
      children: rebateTransactions
          .map((txn) => _buildTransactionItem(txn))
          .toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.bodyM.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textPlaceholder,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (txn.isIncome ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _txnIcon(txn),
              size: 18,
              color: txn.isIncome ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.typeLabel,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTitle,
                  ),
                ),
                if (txn.description != null)
                  Text(
                    txn.description!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${txn.isIncome ? '+' : '-'}\u00a5${txn.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: txn.isIncome ? AppColors.success : AppColors.error,
                ),
              ),
              if (txn.createdAt != null)
                Text(_formatDate(txn.createdAt!), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  IconData _txnIcon(WalletTransaction txn) {
    switch (txn.type) {
      case 'RECHARGE':
        return Icons.add_circle_outline_rounded;
      case 'WITHDRAW':
        return Icons.output_rounded;
      case 'PAYMENT':
        return Icons.shopping_cart_outlined;
      case 'REFUND':
        return Icons.replay_rounded;
      case 'COMMISSION':
      case 'REBATE':
        return Icons.card_giftcard_rounded;
      default:
        return txn.isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (dt.year == now.year) {
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}/${dt.month}/${dt.day}';
  }
}
