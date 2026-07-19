/// 供应商数据模型 - 匹配后端 Supplier entity
class SupplierModel {
  final int id;
  final String name;
  final String? location;
  final double rating;
  final int orderCount;
  final bool certified;
  final List<String> categories;
  final String? responseTime;
  final String? onTimeRate;
  final String? qualityRate;
  final String? contactName;
  final String? contactPhone;
  final String? description;
  final String? logoUrl;
  final DateTime? createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.location,
    this.rating = 0,
    this.orderCount = 0,
    this.certified = false,
    this.categories = const [],
    this.responseTime,
    this.onTimeRate,
    this.qualityRate,
    this.contactName,
    this.contactPhone,
    this.description,
    this.logoUrl,
    this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] ?? 0,
      name: json['companyName'] ?? json['name'] ?? '',
      location: json['location'] ?? json['province'] != null
          ? '${json['province'] ?? ''} ${json['city'] ?? ''}'.trim()
          : null,
      rating: (json['rating'] ?? json['score'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? json['completedOrders'] ?? 0,
      certified: json['certified'] ?? json['verified'] ?? false,
      categories:
          (json['categories'] as List<dynamic>?)?.cast<String>() ??
          (json['mainProducts'] as List<dynamic>?)?.cast<String>() ??
          [],
      responseTime: json['responseTime']?.toString(),
      onTimeRate: json['onTimeRate']?.toString(),
      qualityRate: json['qualityRate']?.toString(),
      contactName: json['contactName'],
      contactPhone: json['contactPhone'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'categories': categories,
  };
}
