import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/news_repository.dart';
import '../providers/news_provider.dart';
import 'news_detail_screen.dart';
import 'package:easy_localization/easy_localization.dart';

/// 新闻资讯列表页 - 对标网站 news.html
class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(newsListProvider.notifier).loadArticles());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsListProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('news.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading && state.articles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.articles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: AppColors.textPlaceholder.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'news.no_news'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(newsListProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.articles.length,
                itemBuilder: (_, i) => _NewsCard(news: state.articles[i]),
              ),
            ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle news;
  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(articleId: news.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppRadius.lgBorder,
          boxShadow: AppShadows.cardSmall,
        ),
        child: Row(
          children: [
            if (news.coverImage != null) ...[
              ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: Image.network(
                  news.coverImage!,
                  width: 100,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 100,
                    height: 72,
                    color: AppColors.pageBg,
                    child: Icon(
                      Icons.image_outlined,
                      size: 28,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (news.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        news.category!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    news.title,
                    style: AppTextStyles.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTitle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (news.publishTime != null)
                        Text(
                          _formatDate(news.publishTime!),
                          style: AppTextStyles.caption,
                        ),
                      const Spacer(),
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppColors.textPlaceholder,
                      ),
                      const SizedBox(width: 4),
                      Text('${news.viewCount}', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return 'common.today'.tr();
    if (diff.inDays < 7) return 'chat.days_ago'.tr(args: ['${diff.inDays}']);
    return '${dt.month}/${dt.day}';
  }
}
