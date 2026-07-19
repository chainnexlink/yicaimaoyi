import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import 'models/smart_match_models.dart';

/// 包装 API 结果 + 原始 JSON，让 UI 可以直接展示大模型输出
class RawResult<T> {
  final T parsed;
  final Map<String, dynamic> raw;
  const RawResult(this.parsed, this.raw);
}

/// SmartMatch 智能匹配 Repository - 与网站 smart-match.html 完全对齐
/// 6 个 API 方法对应网站 5 步流程，不再回退到 mock 数据
class SmartMatchRepository {
  final Dio _dio;
  SmartMatchRepository(this._dio);

  // ======================== Step 1: 品类匹配 ========================

  /// AI 品类匹配: POST /api/v1/smart-match/categories
  /// 输入产品名+图片URL，AI 返回 3-5 个匹配品类 + sessionId
  Future<RawResult<CategoryMatchResult>> matchCategories(
    String productName, {
    String? imageUrl,
  }) async {
    final queryParams = <String, dynamic>{'productName': productName};
    if (imageUrl != null && imageUrl.isNotEmpty) {
      queryParams['imageUrl'] = imageUrl;
    }

    final response = await _dio.post(
      ApiConstants.smartMatchCategories,
      queryParameters: queryParams,
      options: Options(
        headers: {'bypass-tunnel-reminder': 'true'},
        // AI 品类匹配需要较长时间，与网站一致设为 120 秒
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = _unwrapData(response.data);
    final rawMap = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'data': data};
    return RawResult(
      CategoryMatchResult.fromJson(data as Map<String, dynamic>),
      rawMap,
    );
  }

  // ======================== Step 2: 成本参数 ========================

  /// 获取 AI 动态生成的成本参数: POST /api/v1/smart-match/parameters/cost
  /// AI 根据品类生成 5-10 个参数（select/number/text 类型）
  Future<RawResult<List<CostParameter>>> getCostParameters(
    String sessionId,
    String categoryCode,
  ) async {
    final response = await _dio.post(
      ApiConstants.smartMatchParametersCost,
      data: {
        'sessionId': sessionId,
        'categoryCode': categoryCode,
        'parameterStage': 'COST',
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = _unwrapData(response.data);
    final rawMap = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'parameters': data};
    // 网站返回 { parameters: [...] } 或直接返回 [...]
    final list = data is Map<String, dynamic>
        ? (data['parameters'] as List<dynamic>?) ?? []
        : data as List<dynamic>;
    return RawResult(
      list
          .map((e) => CostParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawMap,
    );
  }

  // ======================== Step 3: 成本预估 ========================

  /// 成本预估: POST /api/v1/smart-match/estimate/cost
  /// 基于用户填写的参数，AI 计算成本明细
  /// 超时 120 秒（AI 计算耗时较长）
  Future<RawResult<CostEstimateResult>> estimateCost(
    String sessionId,
    Map<String, dynamic> parameters, {
    String? categoryCode,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'parameters': parameters,
    };
    if (categoryCode != null) body['categoryCode'] = categoryCode;
    if (imageUrl != null && imageUrl.isNotEmpty) body['imageUrl'] = imageUrl;

    final response = await _dio.post(
      ApiConstants.smartMatchEstimateCost,
      data: body,
      options: Options(
        // AI 成本计算可能耗时较长，与网站一致设为 120 秒
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = _unwrapData(response.data);
    final rawMap = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'data': data};
    return RawResult(
      CostEstimateResult.fromJson(data as Map<String, dynamic>),
      rawMap,
    );
  }

  // ======================== Step 4: 工厂报价 ========================

  /// 工厂报价: POST /api/v1/smart-match/estimate/factory-quote
  /// 注意：网站使用 POST + query 参数，不是 GET
  Future<RawResult<FactoryQuoteResult>> getFactoryQuote(
    String sessionId,
    String categoryCode,
  ) async {
    final response = await _dio.post(
      ApiConstants.smartMatchEstimateFactoryQuote,
      queryParameters: {'sessionId': sessionId, 'categoryCode': categoryCode},
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = _unwrapData(response.data);
    final rawMap = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'data': data};
    return RawResult(
      FactoryQuoteResult.fromJson(data as Map<String, dynamic>),
      rawMap,
    );
  }

  // ======================== Step 5: FOB 预估 ========================

  /// 获取 FOB 参数: POST /api/v1/smart-match/parameters/fob
  Future<RawResult<List<CostParameter>>> getFobParameters(
    String sessionId,
    String categoryCode,
  ) async {
    final response = await _dio.post(
      ApiConstants.smartMatchParametersFob,
      data: {
        'sessionId': sessionId,
        'categoryCode': categoryCode,
        'parameterStage': 'FOB',
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = _unwrapData(response.data);
    final rawMap = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'parameters': data};
    final list = data is Map<String, dynamic>
        ? (data['parameters'] as List<dynamic>?) ?? []
        : data as List<dynamic>;
    return RawResult(
      list
          .map((e) => CostParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawMap,
    );
  }

  /// FOB 预估: POST /api/v1/smart-match/estimate/fob
  /// 计算 FOB 成本分解
  Future<RawResult<FobEstimateResult>> estimateFob(
    String sessionId,
    Map<String, dynamic> fobParams, {
    String? supplierCode,
  }) async {
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'fobParameters': fobParams,
    };
    if (supplierCode != null) body['supplierCode'] = supplierCode;

    final response = await _dio.post(
      ApiConstants.smartMatchEstimateFob,
      data: body,
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = _unwrapData(response.data);
    final rawMap = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'data': data};
    return RawResult(
      FobEstimateResult.fromJson(data as Map<String, dynamic>),
      rawMap,
    );
  }

  /// 解包 API 响应: { code: 200, data: {...}, message: "success" }
  dynamic _unwrapData(dynamic data) {
    if (data is Map<String, dynamic>) {
      // 检查是否是标准包装格式
      if (data.containsKey('code') && data.containsKey('data')) {
        final code = data['code'];
        if (code != 200) {
          throw DioException(
            requestOptions: RequestOptions(),
            message: data['message']?.toString() ?? 'error.server_error'.tr(args: [code.toString()]),
            type: DioExceptionType.badResponse,
          );
        }
        return data['data'];
      }
      // 兼容只有 data 字段的格式
      if (data.containsKey('data')) {
        return data['data'];
      }
    }
    return data;
  }
}
