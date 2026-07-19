class DashboardData {
  final List<KpiItem> kpis;
  final List<OrderTrendItem> orderTrend;
  final List<CategoryItem> categories;
  final List<SupplierRankItem> supplierRanking;
  final List<CostItem> costBreakdown;

  const DashboardData({
    this.kpis = const [],
    this.orderTrend = const [],
    this.categories = const [],
    this.supplierRanking = const [],
    this.costBreakdown = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      kpis:
          (json['kpis'] as List<dynamic>?)
              ?.map((e) => KpiItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      orderTrend:
          (json['orderTrend'] as List<dynamic>?)
              ?.map((e) => OrderTrendItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      supplierRanking:
          (json['supplierRanking'] as List<dynamic>?)
              ?.map((e) => SupplierRankItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      costBreakdown:
          (json['costBreakdown'] as List<dynamic>?)
              ?.map((e) => CostItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class KpiItem {
  final String label;
  final String value;
  final String change;

  const KpiItem({
    required this.label,
    required this.value,
    required this.change,
  });

  factory KpiItem.fromJson(Map<String, dynamic> json) {
    return KpiItem(
      label: json['label'] ?? '',
      value: json['value']?.toString() ?? '0',
      change: json['change']?.toString() ?? '',
    );
  }
}

class OrderTrendItem {
  final String month;
  final int count;

  const OrderTrendItem({required this.month, required this.count});

  factory OrderTrendItem.fromJson(Map<String, dynamic> json) {
    return OrderTrendItem(
      month: json['month'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class CategoryItem {
  final String name;
  final int percent;

  const CategoryItem({required this.name, required this.percent});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      name: json['name'] ?? json['category'] ?? '',
      percent: json['percent'] ?? json['percentage'] ?? 0,
    );
  }
}

class SupplierRankItem {
  final int rank;
  final String name;
  final double rating;
  final String amount;

  const SupplierRankItem({
    required this.rank,
    required this.name,
    required this.rating,
    required this.amount,
  });

  factory SupplierRankItem.fromJson(Map<String, dynamic> json) {
    return SupplierRankItem(
      rank: json['rank'] ?? 0,
      name: json['name'] ?? json['supplierName'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      amount: json['amount']?.toString() ?? '0',
    );
  }
}

class CostItem {
  final String label;
  final double ratio;

  const CostItem({required this.label, required this.ratio});

  factory CostItem.fromJson(Map<String, dynamic> json) {
    return CostItem(
      label: json['label'] ?? json['category'] ?? '',
      ratio: (json['ratio'] ?? json['percentage'] ?? 0).toDouble(),
    );
  }
}
