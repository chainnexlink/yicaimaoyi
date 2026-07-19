/// 供应商产品数据模型 - 匹配后端 SupplierProduct entity
class SupplierProductModel {
  final int id;
  final String name;
  final String? category;
  final double? price;
  final double? minOrderQty;
  final String? unit;
  final String? description;
  final String? imageUrl;
  final List<String> images;
  final String status; // ACTIVE, INACTIVE, PENDING
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupplierProductModel({
    required this.id,
    required this.name,
    this.category,
    this.price,
    this.minOrderQty,
    this.unit,
    this.description,
    this.imageUrl,
    this.images = const [],
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierProductModel.fromJson(Map<String, dynamic> json) {
    return SupplierProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['productName'] ?? '',
      category: json['category'] ?? json['categoryName'],
      price: (json['price'] ?? json['unitPrice'])?.toDouble(),
      minOrderQty: (json['minOrderQty'] ?? json['moq'])?.toDouble(),
      unit: json['unit'],
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['mainImage'],
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'price': price,
    'minOrderQty': minOrderQty,
    'unit': unit,
    'description': description,
    'imageUrl': imageUrl,
    'images': images,
    'status': status,
  };

  SupplierProductModel copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    double? minOrderQty,
    String? unit,
    String? description,
    String? imageUrl,
    List<String>? images,
    String? status,
  }) {
    return SupplierProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// 供应商中心概览统计
class SupplierDashboardStats {
  final int totalProducts;
  final int activeProducts;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double monthlyRevenue;
  final double averageRating;
  final int totalInquiries;

  const SupplierDashboardStats({
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.totalRevenue = 0,
    this.monthlyRevenue = 0,
    this.averageRating = 0,
    this.totalInquiries = 0,
  });

  factory SupplierDashboardStats.fromJson(Map<String, dynamic> json) {
    return SupplierDashboardStats(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalInquiries: json['totalInquiries'] ?? 0,
    );
  }
}
