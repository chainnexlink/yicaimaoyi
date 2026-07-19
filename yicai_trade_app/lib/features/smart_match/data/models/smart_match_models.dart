// 智能匹配数据模型 - 与网站 smart-match.html 完全对齐
// 5步流程: 品类匹配 → 成本参数 → 成本预估 → 工厂报价 → FOB预估
import 'package:easy_localization/easy_localization.dart';

// ======================== Step 1: 品类匹配 ========================

/// 品类匹配结果
class CategoryMatchResult {
  final String sessionId;
  final List<MatchedCategory> categories;

  CategoryMatchResult({required this.sessionId, required this.categories});

  factory CategoryMatchResult.fromJson(Map<String, dynamic> json) {
    // 网站返回 matchedCategories，兼容 categories
    final list = json['matchedCategories'] ?? json['categories'];
    return CategoryMatchResult(
      sessionId: json['sessionId'] ?? '',
      categories:
          (list as List<dynamic>?)
              ?.map((e) => MatchedCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 单个匹配品类
class MatchedCategory {
  final String categoryName;
  final String categoryCode;
  final double matchScore;
  final String description;

  MatchedCategory({
    required this.categoryName,
    required this.categoryCode,
    required this.matchScore,
    required this.description,
  });

  factory MatchedCategory.fromJson(Map<String, dynamic> json) {
    // 网站返回 matchScore 为 0-100 整数，需归一化到 0-1
    final rawScore = (json['matchScore'] ?? 0) as num;
    final dScore = rawScore.toDouble();
    final score = dScore > 1 ? dScore / 100.0 : dScore;
    return MatchedCategory(
      categoryName: json['categoryName'] ?? '',
      categoryCode: json['categoryCode'] ?? '',
      matchScore: score,
      description: json['description'] ?? '',
    );
  }
}

// ======================== Step 2: 成本参数 ========================

/// AI 动态生成的参数定义
class CostParameter {
  final String parameterName;
  final String parameterCode;
  final String parameterType; // select, number, text, radio
  final List<String> options;
  final bool allowAIEstimate;
  final String? aiEstimateOption;
  final bool required;
  final String? unit;
  final String? description;
  final String? defaultValue;

  CostParameter({
    required this.parameterName,
    required this.parameterCode,
    required this.parameterType,
    this.options = const [],
    this.allowAIEstimate = false,
    this.aiEstimateOption,
    this.required = true,
    this.unit,
    this.description,
    this.defaultValue,
  });

  factory CostParameter.fromJson(Map<String, dynamic> json) {
    return CostParameter(
      parameterName: json['parameterName'] ?? '',
      parameterCode: json['parameterCode'] ?? '',
      parameterType: json['parameterType'] ?? 'text',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allowAIEstimate: json['allowAIEstimate'] ?? false,
      aiEstimateOption: json['aiEstimateOption'],
      required: json['required'] ?? true,
      unit: json['unit'],
      description: json['description'],
      defaultValue: json['defaultValue'],
    );
  }
}

// ======================== Step 3: 成本预估 ========================

/// 成本预估结果 - 与网站 costBreakdown 完全对齐
class CostEstimateResult {
  // 成本明细（网站字段名）
  final double materialCost;
  final double processingCost;
  final double wasteCost;
  final double packagingCost;
  final double totalCost;
  final String? currency;
  final String? unit;

  // 同平台市场参考（阿里巴巴）
  final double? platformPriceLow;
  final double? platformPriceHigh;
  final String? alibabaReferenceNote;

  // 兼容旧字段
  final double? laborCost;
  final double? shippingCost;
  final double? profit;
  final double? totalCostLow;
  final double? totalCostHigh;
  final String? costSource;

  // 推荐供应商
  final List<RecommendedSupplier> suppliers;

  CostEstimateResult({
    required this.materialCost,
    this.processingCost = 0,
    this.wasteCost = 0,
    required this.packagingCost,
    required this.totalCost,
    this.currency,
    this.unit,
    this.platformPriceLow,
    this.platformPriceHigh,
    this.alibabaReferenceNote,
    this.laborCost,
    this.shippingCost,
    this.profit,
    this.totalCostLow,
    this.totalCostHigh,
    this.costSource,
    this.suppliers = const [],
  });

  factory CostEstimateResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['costBreakdown'] as Map<String, dynamic>? ?? json;

    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      final s = val.toString().replaceAll(RegExp(r'[¥￥,]'), '');
      return double.tryParse(s) ?? 0;
    }

    return CostEstimateResult(
      materialCost: parsePrice(breakdown['materialCost'] ?? breakdown['材料成本']),
      processingCost: parsePrice(
        breakdown['processingCost'] ?? breakdown['加工成本'],
      ),
      wasteCost: parsePrice(breakdown['wasteCost'] ?? breakdown['损耗成本']),
      packagingCost: parsePrice(
        breakdown['packagingCost'] ?? breakdown['包装成本'],
      ),
      totalCost: parsePrice(breakdown['totalCost'] ?? breakdown['总成本']),
      currency: breakdown['currency']?.toString(),
      unit: breakdown['unit']?.toString(),
      platformPriceLow: parsePrice(breakdown['platformPriceLow']),
      platformPriceHigh: parsePrice(breakdown['platformPriceHigh']),
      alibabaReferenceNote: breakdown['alibabaReferenceNote']?.toString(),
      laborCost: parsePrice(breakdown['laborCost'] ?? breakdown['人工成本']),
      shippingCost: parsePrice(breakdown['shippingCost'] ?? breakdown['运输成本']),
      profit: parsePrice(breakdown['profit'] ?? breakdown['利润']),
      totalCostLow: parsePrice(json['totalCostLow']),
      totalCostHigh: parsePrice(json['totalCostHigh']),
      costSource: json['costSource']?.toString(),
      suppliers:
          (json['suggestedSuppliers'] ?? json['suppliers'] as List<dynamic>?)
              ?.map(
                (e) => RecommendedSupplier.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// 获取成本明细列表用于展示
  List<(String, double)> get costBreakdownItems {
    final items = <(String, double)>[];
    if (materialCost > 0) items.add(('smart_match.cost_material'.tr(), materialCost));
    if (processingCost > 0) items.add(('smart_match.cost_processing'.tr(), processingCost));
    if (wasteCost > 0) items.add(('smart_match.cost_waste'.tr(), wasteCost));
    if (packagingCost > 0) items.add(('smart_match.cost_packaging'.tr(), packagingCost));
    // 兼容旧字段
    if (laborCost != null && laborCost! > 0 && processingCost == 0) {
      items.add(('smart_match.cost_labor'.tr(), laborCost!));
    }
    if (shippingCost != null && shippingCost! > 0) {
      items.add(('smart_match.cost_shipping'.tr(), shippingCost!));
    }
    if (profit != null && profit! > 0) items.add(('smart_match.cost_profit'.tr(), profit!));
    return items;
  }

  /// 展示用的总价区间
  String get displayPriceRange {
    if (totalCostLow != null &&
        totalCostLow! > 0 &&
        totalCostHigh != null &&
        totalCostHigh! > 0) {
      return '¥${totalCostLow!.toStringAsFixed(2)} - ¥${totalCostHigh!.toStringAsFixed(2)}';
    }
    return '¥${totalCost.toStringAsFixed(2)}';
  }

  /// 是否有市场参考价数据
  bool get hasMarketReference =>
      (platformPriceLow != null && platformPriceLow! > 0) ||
      (alibabaReferenceNote != null && alibabaReferenceNote!.isNotEmpty);
}

/// 推荐供应商 - 与网站 suggestedSuppliers 对齐
class RecommendedSupplier {
  final String name;
  final String? supplierCode;
  final String? city;
  final String? industrialBelt;
  final String? mainProducts;
  final String? matchReason;
  final double? estimatedCostPrice;
  final int matchScore;
  final double rating;
  final double unitPrice;
  final int deliveryDays;
  final bool certified;

  RecommendedSupplier({
    required this.name,
    this.supplierCode,
    this.city,
    this.industrialBelt,
    this.mainProducts,
    this.matchReason,
    this.estimatedCostPrice,
    required this.matchScore,
    this.rating = 0,
    this.unitPrice = 0,
    this.deliveryDays = 0,
    this.certified = false,
  });

  factory RecommendedSupplier.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      final s = val.toString().replaceAll(RegExp(r'[¥￥,]'), '');
      return double.tryParse(s) ?? 0;
    }

    return RecommendedSupplier(
      name: json['factoryName'] ?? json['name'] ?? json['supplierName'] ?? '',
      supplierCode: json['supplierCode'],
      city: json['city'],
      industrialBelt: json['industrialBelt'],
      mainProducts: json['mainProducts'],
      matchReason: json['matchReason'],
      estimatedCostPrice: parsePrice(json['estimatedCostPrice']),
      matchScore: (json['matchScore'] ?? 0) is int
          ? json['matchScore'] ?? 0
          : ((json['matchScore'] ?? 0) as num).toInt(),
      rating: (json['rating'] ?? 0).toDouble(),
      unitPrice: parsePrice(json['unitPrice']),
      deliveryDays: json['deliveryDays'] ?? 0,
      certified: json['certified'] ?? false,
    );
  }
}

// ======================== Step 4: 工厂报价 ========================

/// 工厂报价结果 - 与网站 quoteBreakdown 完全对齐
class FactoryQuoteResult {
  // 网站新字段
  final double? costPrice;
  final double? platformPriceLow;
  final double? platformPriceHigh;
  final double? industryProfitMarginLow;
  final double? industryProfitMarginHigh;
  final String? industryReferenceNote;
  final double quoteLow;
  final double quoteHigh;
  final String? currency;
  final String? unit;

  // 兼容旧字段
  final double profitMarginLow;
  final double profitMarginHigh;
  final List<SupplierQuote> supplierQuotes;

  FactoryQuoteResult({
    this.costPrice,
    this.platformPriceLow,
    this.platformPriceHigh,
    this.industryProfitMarginLow,
    this.industryProfitMarginHigh,
    this.industryReferenceNote,
    required this.quoteLow,
    required this.quoteHigh,
    this.currency,
    this.unit,
    this.profitMarginLow = 0,
    this.profitMarginHigh = 0,
    this.supplierQuotes = const [],
  });

  factory FactoryQuoteResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['quoteBreakdown'] as Map<String, dynamic>? ?? json;

    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      final s = val.toString().replaceAll(RegExp(r'[¥￥,]'), '');
      return double.tryParse(s) ?? 0;
    }

    return FactoryQuoteResult(
      costPrice: parsePrice(breakdown['costPrice']),
      platformPriceLow: parsePrice(breakdown['platformPriceLow']),
      platformPriceHigh: parsePrice(breakdown['platformPriceHigh']),
      industryProfitMarginLow:
          (breakdown['industryProfitMarginLow'] ?? json['profitMarginLow'] ?? 0)
              .toDouble(),
      industryProfitMarginHigh:
          (breakdown['industryProfitMarginHigh'] ??
                  json['profitMarginHigh'] ??
                  0)
              .toDouble(),
      industryReferenceNote: breakdown['industryReferenceNote']?.toString(),
      quoteLow: parsePrice(breakdown['factoryQuoteLow'] ?? json['quoteLow']),
      quoteHigh: parsePrice(breakdown['factoryQuoteHigh'] ?? json['quoteHigh']),
      currency: breakdown['currency']?.toString(),
      unit: breakdown['unit']?.toString(),
      profitMarginLow:
          (breakdown['industryProfitMarginLow'] ?? json['profitMarginLow'] ?? 0)
              .toDouble(),
      profitMarginHigh:
          (breakdown['industryProfitMarginHigh'] ??
                  json['profitMarginHigh'] ??
                  0)
              .toDouble(),
      supplierQuotes:
          (json['supplierQuotes'] as List<dynamic>?)
              ?.map((e) => SupplierQuote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 供应商报价明细 - 与网站 supplierQuotes 对齐
class SupplierQuote {
  final String supplierName;
  final String? supplierCode;
  final String? city;
  final String? industrialBelt;
  final String? mainProducts;
  final int matchScore;
  final String? matchReason;
  final double? estimatedCostPrice;
  final double quoteLow;
  final double quoteHigh;
  final double quotePrice; // 兼容旧字段（=quoteLow）
  final int deliveryDays;
  final int moq;
  final List<String> advantages;

  SupplierQuote({
    required this.supplierName,
    this.supplierCode,
    this.city,
    this.industrialBelt,
    this.mainProducts,
    this.matchScore = 0,
    this.matchReason,
    this.estimatedCostPrice,
    this.quoteLow = 0,
    this.quoteHigh = 0,
    this.quotePrice = 0,
    this.deliveryDays = 0,
    this.moq = 0,
    this.advantages = const [],
  });

  factory SupplierQuote.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      final s = val.toString().replaceAll(RegExp(r'[¥￥,]'), '');
      return double.tryParse(s) ?? 0;
    }

    final low = parsePrice(json['quoteLow']);
    final high = parsePrice(json['quoteHigh']);
    final price = parsePrice(json['quotePrice']);

    return SupplierQuote(
      supplierName: json['factoryName'] ?? json['supplierName'] ?? '',
      supplierCode: json['supplierCode'],
      city: json['city'],
      industrialBelt: json['industrialBelt'],
      mainProducts: json['mainProducts'],
      matchScore: (json['matchScore'] ?? 0) is int
          ? json['matchScore'] ?? 0
          : ((json['matchScore'] ?? 0) as num).toInt(),
      matchReason: json['matchReason'],
      estimatedCostPrice: parsePrice(json['estimatedCostPrice']),
      quoteLow: low > 0 ? low : price,
      quoteHigh: high > 0 ? high : price,
      quotePrice: price > 0 ? price : low,
      deliveryDays: json['deliveryDays'] ?? 0,
      moq: json['moq'] ?? 0,
      advantages:
          (json['advantages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ======================== Step 5: FOB 预估 ========================

/// FOB 预估结果 - 与网站 fobBreakdown 完全对齐
class FobEstimateResult {
  // 网站新字段
  final double costPrice;
  final double domesticFreight;
  final String? fromCity;
  final String? toPort;
  final double portCharges;
  final double customsClearance;
  final double fobPrice;
  final String? currency;
  final String? unit;

  // 兼容旧字段
  final double? inlandFreight;
  final double? portFee;
  final double? customsFee;
  final double? insurance;
  final double? totalFob;
  final double? platformServiceFee;
  final double? rebate;

  // 供应商FOB价格列表
  final List<SupplierFobPrice> supplierFOBPrices;

  FobEstimateResult({
    this.costPrice = 0,
    this.domesticFreight = 0,
    this.fromCity,
    this.toPort,
    this.portCharges = 0,
    this.customsClearance = 0,
    this.fobPrice = 0,
    this.currency,
    this.unit,
    this.inlandFreight,
    this.portFee,
    this.customsFee,
    this.insurance,
    this.totalFob,
    this.platformServiceFee,
    this.rebate,
    this.supplierFOBPrices = const [],
  });

  factory FobEstimateResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['fobBreakdown'] as Map<String, dynamic>? ?? json;

    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      final s = val.toString().replaceAll(RegExp(r'[¥￥,]'), '');
      return double.tryParse(s) ?? 0;
    }

    return FobEstimateResult(
      costPrice: parsePrice(breakdown['costPrice'] ?? breakdown['产品成本']),
      domesticFreight: parsePrice(
        breakdown['domesticFreight'] ?? breakdown['国内运费'],
      ),
      fromCity: breakdown['fromCity']?.toString(),
      toPort: breakdown['toPort']?.toString(),
      portCharges: parsePrice(breakdown['portCharges'] ?? breakdown['港口杂费']),
      customsClearance: parsePrice(
        breakdown['customsClearance'] ?? breakdown['报关费用'],
      ),
      fobPrice: parsePrice(breakdown['fobPrice'] ?? breakdown['FOB价格']),
      currency: breakdown['currency']?.toString(),
      unit: breakdown['unit']?.toString(),
      inlandFreight: parsePrice(
        breakdown['inlandFreight'] ?? breakdown['国内运费'],
      ),
      portFee: parsePrice(breakdown['portFee'] ?? breakdown['港口费']),
      customsFee: parsePrice(breakdown['customsFee'] ?? breakdown['报关费']),
      insurance: parsePrice(breakdown['insurance'] ?? breakdown['保险']),
      totalFob: parsePrice(
        json['totalFob'] ?? breakdown['totalFob'] ?? breakdown['fobPrice'],
      ),
      platformServiceFee: json['platformServiceFee'] != null
          ? parsePrice(json['platformServiceFee'])
          : null,
      rebate: json['rebate'] != null ? parsePrice(json['rebate']) : null,
      supplierFOBPrices:
          (json['supplierFOBPrices'] as List<dynamic>?)
              ?.map((e) => SupplierFobPrice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 获取 FOB 成本分解列表用于展示
  List<(String, double)> get fobBreakdownItems {
    final items = <(String, double)>[];
    if (costPrice > 0) {
      items.add(('smart_match.fob_cost_price'.tr(), costPrice));
    }
    final freight = domesticFreight > 0
        ? domesticFreight
        : (inlandFreight ?? 0);
    if (freight > 0) items.add(('smart_match.fob_domestic_freight'.tr(), freight));
    final port = portCharges > 0 ? portCharges : (portFee ?? 0);
    if (port > 0) items.add(('smart_match.fob_port_charges'.tr(), port));
    final customs = customsClearance > 0 ? customsClearance : (customsFee ?? 0);
    if (customs > 0) items.add(('smart_match.fob_customs'.tr(), customs));
    if (insurance != null && insurance! > 0) items.add(('smart_match.fob_insurance'.tr(), insurance!));
    return items;
  }

  /// 最终 FOB 价格
  double get displayFobPrice {
    if (fobPrice > 0) return fobPrice;
    return totalFob ?? 0;
  }

  /// 运输路线描述
  String? get routeDescription {
    if (fromCity != null && toPort != null) {
      return '$fromCity → $toPort';
    }
    return null;
  }
}

/// 供应商 FOB 价格
class SupplierFobPrice {
  final String factoryName;
  final String? city;
  final double fobPrice;
  final double domesticFreight;
  final int estimatedDeliveryDays;

  SupplierFobPrice({
    required this.factoryName,
    this.city,
    required this.fobPrice,
    this.domesticFreight = 0,
    this.estimatedDeliveryDays = 0,
  });

  factory SupplierFobPrice.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      final s = val.toString().replaceAll(RegExp(r'[¥￥,]'), '');
      return double.tryParse(s) ?? 0;
    }

    return SupplierFobPrice(
      factoryName: json['factoryName'] ?? '',
      city: json['city'],
      fobPrice: parsePrice(json['fobPrice']),
      domesticFreight: parsePrice(json['domesticFreight']),
      estimatedDeliveryDays: json['estimatedDeliveryDays'] ?? 0,
    );
  }
}
