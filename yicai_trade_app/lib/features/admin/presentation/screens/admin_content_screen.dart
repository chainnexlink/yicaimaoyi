import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../news/data/news_repository.dart';
import '../../../news/presentation/providers/news_provider.dart';

/// 内容管理页面 - 公告、轮播图、资讯管理
class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 公告数据（从后端加载后填充）
  final _announcements = <_AnnounceItem>[];

  // 轮播图数据（从后端加载后填充）
  final _banners = <_BannerItem>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(newsListProvider.notifier).loadArticles());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('admin.content_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'admin.announcements'.tr()),
            Tab(text: 'admin.banners'.tr()),
            Tab(text: 'admin.articles'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncementTab(),
          _buildBannerTab(),
          _buildArticleTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNew,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
      ),
    );
  }

  // ====== 公告管理 ======

  Widget _buildAnnouncementTab() {
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'admin.no_announcements'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 8),
            Text('admin.add_announcement'.tr(), style: AppTextStyles.caption),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) =>
          _buildAnnounceCard(_announcements[index]),
    );
  }

  Widget _buildAnnounceCard(_AnnounceItem item) {
    final isActive = item.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                if (item.isTop)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'admin.pinned'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.bodyL.copyWith(
                      color: AppColors.textTitle,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isActive
                                ? AppColors.success
                                : AppColors.textPlaceholder)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'admin.publish'.tr() : 'admin.take_offline'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive
                          ? AppColors.success
                          : AppColors.textPlaceholder,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              item.content,
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 底部操作
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 13,
                  color: AppColors.textPlaceholder,
                ),
                const SizedBox(width: 4),
                Text(
                  item.createdAt,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPlaceholder,
                  ),
                ),
                const Spacer(),
                _actionBtn(
                  isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  isActive ? 'admin.take_offline'.tr() : 'admin.publish'.tr(),
                  isActive ? AppColors.warning : AppColors.success,
                  () => setState(() {
                    final idx = _announcements.indexOf(item);
                    _announcements[idx] = _AnnounceItem(
                      item.id,
                      item.title,
                      item.content,
                      isActive ? 'inactive' : 'active',
                      item.createdAt,
                      item.isTop,
                    );
                  }),
                ),
                const SizedBox(width: 12),
                _actionBtn(
                  item.isTop
                      ? Icons.vertical_align_bottom_rounded
                      : Icons.vertical_align_top_rounded,
                  item.isTop ? 'admin.unpin'.tr() : 'admin.pinned'.tr(),
                  AppColors.catPurple,
                  () => setState(() {
                    final idx = _announcements.indexOf(item);
                    _announcements[idx] = _AnnounceItem(
                      item.id,
                      item.title,
                      item.content,
                      item.status,
                      item.createdAt,
                      !item.isTop,
                    );
                  }),
                ),
                const SizedBox(width: 12),
                _actionBtn(
                  Icons.delete_outline_rounded,
                  'common.delete'.tr(),
                  AppColors.error,
                  () => _confirmDelete('admin.announcements'.tr(), () {
                    setState(() => _announcements.remove(item));
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====== 轮播图管理 ======

  Widget _buildBannerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _banners.length,
      itemBuilder: (context, index) => _buildBannerCard(_banners[index]),
    );
  }

  Widget _buildBannerCard(_BannerItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 图片占位
            Container(
              width: 100,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textTitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.position,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${'common.sort'.tr()}: ${item.sortOrder}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: item.enabled,
              onChanged: (v) => setState(() {
                final idx = _banners.indexOf(item);
                _banners[idx] = _BannerItem(
                  item.id,
                  item.title,
                  item.position,
                  v,
                  item.sortOrder,
                );
              }),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textPlaceholder,
              inactiveTrackColor: AppColors.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }

  // ====== 资讯文章 ======

  Widget _buildArticleTab() {
    final newsState = ref.watch(newsListProvider);
    if (newsState.isLoading && newsState.articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (newsState.articles.isEmpty) {
      return Center(
        child: Text(
          'admin.no_articles'.tr(),
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPlaceholder),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(newsListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: newsState.articles.length,
        itemBuilder: (context, index) =>
            _buildArticleCard(newsState.articles[index]),
      ),
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    final isPublished = article.status == 'PUBLISHED';
    final dateStr = article.publishTime != null
        ? '${article.publishTime!.year}-${article.publishTime!.month.toString().padLeft(2, '0')}-${article.publishTime!.day.toString().padLeft(2, '0')}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (article.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.catBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.category!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.catBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPublished ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPublished ? 'admin.publish'.tr() : 'common.draft'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isPublished ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            article.title,
            style: AppTextStyles.bodyL.copyWith(
              color: AppColors.textTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 12,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textPlaceholder,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.remove_red_eye_outlined,
                size: 12,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 4),
              Text(
                '${article.viewCount}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textPlaceholder,
                ),
              ),
              const Spacer(),
              _actionBtn(
                Icons.edit_outlined,
                'common.edit'.tr(),
                AppColors.catBlue,
                () {
                  _showSnack('admin.article_edit_coming'.tr());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====== 通用组件 ======

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _addNew() {
    final tabName = [
      'admin.announcements'.tr(),
      'admin.banners'.tr(),
      'admin.articles'.tr(),
    ][_tabController.index];
    _showSnack('common.new_item'.tr(args: [tabName]));
  }

  void _confirmDelete(String type, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          'common.confirm_delete'.tr(),
          style: AppTextStyles.headingS,
        ),
        content: Text(
          'admin.confirm_delete_content'.tr(args: [type]),
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.cardBgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      );
    }
  }
}

// ====== 数据模型 ======

class _AnnounceItem {
  final int id;
  final String title;
  final String content;
  final String status;
  final String createdAt;
  final bool isTop;
  const _AnnounceItem(
    this.id,
    this.title,
    this.content,
    this.status,
    this.createdAt,
    this.isTop,
  );
}

class _BannerItem {
  final int id;
  final String title;
  final String position;
  final bool enabled;
  final int sortOrder;
  const _BannerItem(
    this.id,
    this.title,
    this.position,
    this.enabled,
    this.sortOrder,
  );
}
