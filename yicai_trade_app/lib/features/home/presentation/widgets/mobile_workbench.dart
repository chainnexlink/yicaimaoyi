import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// Task-first home layout for phones, tablets, and landscape screens.
class MobileWorkbench extends StatelessWidget {
  const MobileWorkbench({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final content = wide
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _ActiveWork()),
                  SizedBox(width: 18),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _QuickTasks(compact: true),
                        SizedBox(height: 18),
                        _MarketSnapshot(),
                      ],
                    ),
                  ),
                ],
              )
            : const Column(
                children: [
                  _QuickTasks(),
                  SizedBox(height: 20),
                  _ActiveWork(),
                  SizedBox(height: 20),
                  _MarketSnapshot(),
                ],
              );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                16,
                wide ? 24 : 16,
                112,
              ),
              child: Column(
                children: [
                  const _SourcingBrief(),
                  const SizedBox(height: 20),
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SourcingBrief extends StatelessWidget {
  const _SourcingBrief();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123B72), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242563EB),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 660;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'app_home.demo_workspace'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'app_home.brief_title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: horizontal ? 25 : 22,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'app_home.brief_subtitle'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroAction(
                label: 'home.smart_match'.tr(),
                icon: Icons.auto_awesome_rounded,
                filled: true,
                route: RouteNames.smartMatch,
              ),
              _HeroAction(
                label: 'auction.start_auction'.tr(),
                icon: Icons.gavel_rounded,
                route: RouteNames.auctionCreate,
              ),
            ],
          );
          if (horizontal) {
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 24),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 18), actions],
          );
        },
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  final bool filled;

  const _HeroAction({
    required this.label,
    required this.icon,
    required this.route,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: filled ? AppColors.primaryDark : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTasks extends StatelessWidget {
  final bool compact;
  const _QuickTasks({this.compact = false});

  @override
  Widget build(BuildContext context) {
    const tasks = [
      (
        Icons.add_business_rounded,
        'app_home.post_rfq',
        AppColors.secondary,
        RouteNames.publishDemand,
      ),
      (
        Icons.gavel_rounded,
        'app_home.auctions',
        AppColors.catPurple,
        RouteNames.auctionList,
      ),
      (
        Icons.factory_outlined,
        'home.supplier_library',
        AppColors.featureTeal,
        RouteNames.supplierList,
      ),
      (
        Icons.document_scanner_outlined,
        'home.contract_manage',
        AppColors.catBlue,
        RouteNames.contractList,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Title('app_home.quick_actions'.tr()),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: compact ? 1.35 : 0.9,
          ),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => context.push(task.$4),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: task.$3.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(task.$1, color: task.$3, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.$2.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActiveWork extends StatelessWidget {
  const _ActiveWork();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Title('app_home.active_work'.tr())),
            TextButton(
              onPressed: () => context.go(RouteNames.orders),
              child: Text('app_home.view_all'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Panel(
          child: Column(
            children: const [
              _WorkRow(
                Icons.request_quote_outlined,
                AppColors.secondary,
                'RFQ-20260715-042',
                'app_home.demo_rfq',
                'app_home.status_quoting',
                RouteNames.inquiryList,
              ),
              Divider(indent: 70),
              _WorkRow(
                Icons.precision_manufacturing_outlined,
                AppColors.featureTeal,
                'PO-20260708-118',
                'app_home.demo_production',
                '68%',
                RouteNames.productionMonitor,
                progress: .68,
              ),
              Divider(indent: 70),
              _WorkRow(
                Icons.timer_outlined,
                AppColors.catPurple,
                'ERB-20260715-009',
                'app_home.demo_auction',
                '02:18:36',
                RouteNames.auctionList,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitleKey;
  final String status;
  final String route;
  final double? progress;

  const _WorkRow(
    this.icon,
    this.color,
    this.title,
    this.subtitleKey,
    this.status,
    this.route, {
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      _DemoBadge(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleKey.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: color,
                        backgroundColor: color.withValues(alpha: .10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status.tr(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketSnapshot extends StatelessWidget {
  const _MarketSnapshot();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Title('app_home.market_snapshot'.tr()),
        const SizedBox(height: 10),
        _Panel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Metric(
                  'app_home.metric_benchmark'.tr(),
                  'USD 2.84 / pc',
                  '-4.2%',
                  true,
                ),
                const SizedBox(height: 14),
                _Metric(
                  'app_home.metric_lead_time'.tr(),
                  '24–31 days',
                  'FOB Ningbo',
                  false,
                ),
                const SizedBox(height: 14),
                _Metric(
                  'app_home.metric_suppliers'.tr(),
                  '18',
                  '6 verified',
                  false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool positive;
  const _Metric(this.label, this.value, this.note, this.positive);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Text(
          note,
          style: TextStyle(
            color: positive ? AppColors.success : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textTitle,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      letterSpacing: -.2,
    ),
  );
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: child,
  );
}

class _DemoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.infoBg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      'app_home.demo'.tr(),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
