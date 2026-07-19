import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/section_header.dart';

/// 资讯双Tab V2 - 更精致的卡片式新闻列表
class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'home.news_title'.tr()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: TabBar(
                    labelColor: AppColors.textOnPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerHeight: 0,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: [
                      Tab(text: 'Platform Insights'),
                      Tab(text: 'home.news_tab_industry'.tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    children: [_PlatformNewsList(), _IndustryNewsList()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformNewsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const news = [
      _NewsItem(
        tag: 'Smart Match',
        tagColor: AppColors.featureRed,
        title: 'How Our AI-Powered Smart Matching Connects You with the Best Suppliers',
        desc: 'Discover how our intelligent supplier matching technology helps global buyers.',
        date: '2026-03-06',
      ),
      _NewsItem(
        tag: 'Auction',
        tagColor: AppColors.featureYellow,
        title: 'Save Up to 30% on Procurement Costs with Auction',
        desc: 'Our smart procurement auction system lets suppliers compete for your orders.',
        date: '2026-03-05',
      ),
      _NewsItem(
        tag: 'Supply Chain',
        tagColor: AppColors.featureTeal,
        title: 'One-Stop Sourcing: All Categories Covered',
        desc: 'Full-category supply chain services covering 50+ industries.',
        date: '2026-03-04',
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: news.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) => _NewsRow(item: news[index]),
    );
  }
}

class _IndustryNewsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final news = [
      _NewsItem(
        tag: 'home.news_tag_trend'.tr(),
        tagColor: AppColors.catBlue,
        title: 'home.news_article_1_title'.tr(),
        desc: 'home.news_article_1_desc'.tr(),
        date: '2026-02-10',
      ),
      _NewsItem(
        tag: 'home.news_tag_overseas'.tr(),
        tagColor: AppColors.catPurple,
        title: 'home.news_article_2_title'.tr(),
        desc: 'home.news_article_2_desc'.tr(),
        date: '2026-02-08',
      ),
      _NewsItem(
        tag: 'home.news_tag_policy'.tr(),
        tagColor: AppColors.secondary,
        title: 'home.news_article_3_title'.tr(),
        desc: 'home.news_article_3_desc'.tr(),
        date: '2026-02-05',
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: news.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) => _NewsRow(item: news[index]),
    );
  }
}

class _NewsItem {
  final String tag;
  final Color tagColor;
  final String title;
  final String desc;
  final String date;
  const _NewsItem({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.desc,
    required this.date,
  });
}

class _NewsRow extends StatelessWidget {
  final _NewsItem item;
  const _NewsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => GoRouter.of(context).push(RouteNames.newsList),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.tagColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                item.tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: item.tagColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: AppTextStyles.headingS.copyWith(
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.desc,
              style: AppTextStyles.bodyS.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.date,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPlaceholder,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
