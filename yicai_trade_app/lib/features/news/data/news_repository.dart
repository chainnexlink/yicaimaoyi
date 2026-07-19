import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class NewsArticle {
  final int id;
  final String? newsNo;
  final String title;
  final String? summary;
  final String? content;
  final String? coverImage;
  final String? category;
  final String? authorName;
  final String? authorRole;
  final String? source;
  final String? lang;
  final int? industryId;
  final String? industryName;
  final String status;
  final int viewCount;
  final int commentCount;
  final int likeCount;
  final int shareCount;
  final bool isTop;
  final bool isRecommend;
  final List<String> tags;
  final DateTime? publishTime;
  final DateTime? createdAt;

  const NewsArticle({
    required this.id,
    this.newsNo,
    required this.title,
    this.summary,
    this.content,
    this.coverImage,
    this.category,
    this.authorName,
    this.authorRole,
    this.source,
    this.lang,
    this.industryId,
    this.industryName,
    this.status = 'PUBLISHED',
    this.viewCount = 0,
    this.commentCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,
    this.isTop = false,
    this.isRecommend = false,
    this.tags = const [],
    this.publishTime,
    this.createdAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    id: json['id'] ?? 0,
    newsNo: json['newsNo'],
    title: json['title'] ?? '',
    summary: json['summary'],
    content: json['content'],
    coverImage: json['coverImage'],
    category: json['category'],
    authorName: json['authorName'],
    authorRole: json['authorRole'],
    source: json['source'],
    lang: json['lang'],
    industryId: json['industryId'],
    industryName: json['industryName'],
    status: json['status'] ?? 'PUBLISHED',
    viewCount: json['viewCount'] ?? 0,
    commentCount: json['commentCount'] ?? 0,
    likeCount: json['likeCount'] ?? 0,
    shareCount: json['shareCount'] ?? 0,
    isTop: json['isTop'] == true,
    isRecommend: json['isRecommend'] == true,
    tags: json['tags'] is List
        ? (json['tags'] as List).map((e) => e.toString()).toList()
        : const [],
    publishTime: json['publishTime'] != null
        ? DateTime.tryParse(json['publishTime'].toString())
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );
}

/// 新闻评论模型 - 对标网站 news-detail.html 的评论区
class NewsComment {
  final int id;
  final int articleId;
  final String author;
  final String? authorRole;
  final String? authorAvatar;
  final String content;
  final int likeCount;
  final int replyCount;
  final List<NewsComment> replies;
  final DateTime? createdAt;

  const NewsComment({
    required this.id,
    required this.articleId,
    required this.author,
    this.authorRole,
    this.authorAvatar,
    required this.content,
    this.likeCount = 0,
    this.replyCount = 0,
    this.replies = const [],
    this.createdAt,
  });

  factory NewsComment.fromJson(Map<String, dynamic> json) => NewsComment(
    id: json['id'] ?? 0,
    articleId: json['articleId'] ?? 0,
    author: json['author'] ?? '',
    authorRole: json['authorRole'],
    authorAvatar: json['authorAvatar'],
    content: json['content'] ?? '',
    likeCount: json['likeCount'] ?? 0,
    replyCount: json['replyCount'] ?? 0,
    replies: json['replies'] is List
        ? (json['replies'] as List)
              .map((e) => NewsComment.fromJson(e as Map<String, dynamic>))
              .toList()
        : const [],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {'articleId': articleId, 'content': content};
}

class Industry {
  final int id;
  final String name;
  final String? nameEn;
  final int sortOrder;
  final String status;

  const Industry({
    required this.id,
    required this.name,
    this.nameEn,
    this.sortOrder = 0,
    this.status = 'ACTIVE',
  });

  factory Industry.fromJson(Map<String, dynamic> json) => Industry(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    nameEn: json['nameEn'],
    sortOrder: json['sortOrder'] ?? 0,
    status: json['status'] ?? 'ACTIVE',
  );
}

/// 新闻仓库 - 匹配后端 PublicNewsController
class NewsRepository {
  final Dio _dio;
  NewsRepository(this._dio);

  /// 获取最新文章: GET /api/news/latest
  Future<List<NewsArticle>> getLatest({
    int size = 4,
    String lang = 'en',
  }) async {
    final r = await _dio.get(
      ApiConstants.newsLatest,
      queryParameters: {'size': size, 'lang': lang},
    );
    return _parseList(r.data);
  }

  /// 分页查询文章列表: GET /api/news/list
  Future<PageResult<NewsArticle>> list({
    int page = 0,
    int size = 10,
    String lang = 'en',
    int? industryId,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size, 'lang': lang};
    if (industryId != null) params['industryId'] = industryId;
    final r = await _dio.get(ApiConstants.newsList, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 获取文章详情: GET /api/news/{id}
  Future<NewsArticle> getDetail(int id) async {
    final r = await _dio.get(ApiConstants.newsDetail(id));
    return NewsArticle.fromJson(_unwrap(r.data));
  }

  /// 获取行业品类列表: GET /api/news/industries
  Future<List<Industry>> getIndustries() async {
    final r = await _dio.get(ApiConstants.newsIndustries);
    final body = r.data is Map<String, dynamic>
        ? (r.data['data'] ?? r.data)
        : r.data;
    if (body is List) {
      return body
          .map((e) => Industry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 增加文章浏览量: POST /api/admin/content/news/{id}/view
  /// 后端 ContentController 端点
  Future<void> incrementViewCount(int articleId) async {
    try {
      await _dio.post('/api/admin/content/news/$articleId/view');
    } catch (_) {}
  }

  /// 获取推荐文章: GET /api/admin/content/news/recommend
  /// 后端 ContentController 端点
  Future<List<NewsArticle>> getRecommended({int size = 6}) async {
    try {
      final r = await _dio.get(
        '/api/admin/content/news/recommend',
        queryParameters: {'size': size},
      );
      return _parseList(r.data);
    } catch (_) {
      return [];
    }
  }

  List<NewsArticle> _parseList(dynamic data) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is List) {
      return body
          .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['data'] is Map<String, dynamic> ? data['data'] : data;
    }
    return {};
  }

  PageResult<NewsArticle> _parsePage(dynamic data) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => NewsArticle.fromJson(j));
    }
    if (body is List) {
      final list = _parseList(data);
      return PageResult(
        content: list,
        totalElements: list.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: list.length,
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
