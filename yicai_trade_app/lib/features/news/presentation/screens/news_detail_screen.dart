import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/news_repository.dart';
import '../providers/news_provider.dart';
import 'package:easy_localization/easy_localization.dart';

/// 新闻详情页 - 对接后端 PublicNewsController + ContentController
class NewsDetailScreen extends ConsumerStatefulWidget {
  final int articleId;
  const NewsDetailScreen({super.key, required this.articleId});

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(newsDetailProvider(widget.articleId).notifier).loadDetail(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsDetailProvider(widget.articleId));
    final news = state.article;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: Text('news.detail_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ],
      ),
      body: state.isLoading && news == null
          ? const Center(child: CircularProgressIndicator())
          : news == null
          ? Center(
              child: Text(
                state.error ?? 'common.load_failed'.tr(),
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分类标签
                  if (news.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  // 标题
                  Text(news.title, style: AppTextStyles.headingL),
                  const SizedBox(height: 10),

                  // 作者、时间、阅读量
                  _buildMeta(news),
                  const SizedBox(height: 16),

                  // 标签
                  if (news.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: news.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.searchBarBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // 封面图
                  if (news.coverImage != null) ...[
                    ClipRRect(
                      borderRadius: AppRadius.lgBorder,
                      child: Image.network(
                        news.coverImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 正文
                  Text(
                    news.content ?? news.summary ?? 'common.no_data'.tr(),
                    style: AppTextStyles.bodyL.copyWith(
                      color: AppColors.textBody,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 互动栏
                  _buildInteractionBar(news),
                  const SizedBox(height: 24),

                  // 推荐文章
                  if (state.recommended.isNotEmpty) ...[
                    _buildRecommendedSection(state.recommended),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMeta(NewsArticle news) {
    return Row(
      children: [
        if (news.authorName != null) ...[
          Icon(
            Icons.person_outline_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(news.authorName!, style: AppTextStyles.caption),
          if (news.authorRole != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${news.authorRole})',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
          const SizedBox(width: 16),
        ],
        if (news.publishTime != null) ...[
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${news.publishTime!.year}-${news.publishTime!.month.toString().padLeft(2, '0')}-${news.publishTime!.day.toString().padLeft(2, '0')}',
            style: AppTextStyles.caption,
          ),
        ],
        const Spacer(),
        Icon(
          Icons.visibility_outlined,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text('${news.viewCount}', style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildInteractionBar(NewsArticle news) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _interactionItem(
            icon: Icons.visibility_outlined,
            label: 'news.read_count'.tr(args: ['${news.viewCount}']),
            color: AppColors.textSecondary,
          ),
          _interactionItem(
            icon: Icons.share_outlined,
            label: 'news.share'.tr(),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _interactionItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection(List<NewsArticle> recommended) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('news.recommended'.tr(), style: AppTextStyles.headingS),
        const SizedBox(height: 10),
        ...recommended
            .take(4)
            .map(
              (r) => GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(articleId: r.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.title,
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.textTitle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textPlaceholder,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
