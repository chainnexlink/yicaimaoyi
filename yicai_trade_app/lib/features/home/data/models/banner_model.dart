/// Banner 数据模型
class BannerModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final int sortOrder;

  const BannerModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    this.sortOrder = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'],
      linkUrl: json['linkUrl'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}
