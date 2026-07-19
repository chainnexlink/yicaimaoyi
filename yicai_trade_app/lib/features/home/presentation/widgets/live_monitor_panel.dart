import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

/// 实时监控面板 V3 - 浅色卡片风格 + LIVE + 自动滚动
class LiveMonitorPanel extends StatefulWidget {
  const LiveMonitorPanel({super.key});

  @override
  State<LiveMonitorPanel> createState() => _LiveMonitorPanelState();
}

class _LiveMonitorPanelState extends State<LiveMonitorPanel> {
  final _scrollController = ScrollController();
  Timer? _scrollTimer;

  static const _orders = [
    _OrderItem(
      id: 'ORD-20260315-8821',
      text: 'Ceramic Mug production 35% completed',
      progress: 0.35,
      status: 'production',
    ),
    _OrderItem(
      id: 'ORD-20260314-7193',
      text: 'LED Panel shipping from Shenzhen',
      progress: 0.72,
      status: 'shipping',
    ),
    _OrderItem(
      id: 'ORD-20260313-5540',
      text: 'Textile quality inspection passed',
      progress: 0.90,
      status: 'quality',
    ),
    _OrderItem(
      id: 'ORD-20260312-4201',
      text: 'Steel Parts order completed',
      progress: 1.0,
      status: 'completed',
    ),
    _OrderItem(
      id: 'ORD-20260311-3388',
      text: 'Electronics assembly 60% done',
      progress: 0.60,
      status: 'production',
    ),
    _OrderItem(
      id: 'ORD-20260310-2100',
      text: 'Packaging materials shipped',
      progress: 0.85,
      status: 'shipping',
    ),
    _OrderItem(
      id: 'ORD-20260309-1755',
      text: 'Furniture coating quality check',
      progress: 0.45,
      status: 'quality',
    ),
    _OrderItem(
      id: 'ORD-20260308-0991',
      text: 'Plastic molding production started',
      progress: 0.15,
      status: 'production',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final nextScroll = currentScroll + 56;
        if (nextScroll >= maxScroll) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        } else {
          _scrollController.animateTo(
            nextScroll,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final panelHeight = isTablet ? 260.0 : 200.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.featureTealSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.featureTeal.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulseDot(),
                const SizedBox(width: 8),
                Text(
                  'home.live_monitor_title'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-Time Order Monitoring',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          // 滚动列表
          SizedBox(
            height: panelHeight,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.06, 0.94, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _LiveOrderRow(order: _orders[index]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: Material(
                color: AppColors.featureTeal,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () =>
                      GoRouter.of(context).push(RouteNames.productionMonitor),
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Text(
                      'home.enter_monitor_center'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItem {
  final String id;
  final String text;
  final double progress;
  final String status;
  const _OrderItem({
    required this.id,
    required this.text,
    required this.progress,
    required this.status,
  });
}

class _LiveOrderRow extends StatelessWidget {
  final _OrderItem order;
  const _LiveOrderRow({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case 'production':
        return AppColors.featureYellow;
      case 'shipping':
        return AppColors.primary;
      case 'quality':
        return AppColors.secondary;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (order.status) {
      case 'production':
        return Icons.precision_manufacturing_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'quality':
        return Icons.verified_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_statusIcon, size: 18, color: _statusColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    order.text,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textBody,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: order.progress,
                      backgroundColor: AppColors.border,
                      color: _statusColor,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(order.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8 + (_controller.value * 2),
          height: 8 + (_controller.value * 2),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(
              alpha: 0.7 + (_controller.value * 0.3),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
