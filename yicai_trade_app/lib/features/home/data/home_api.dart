import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'models/banner_model.dart';

/// 首页 API
class HomeApi {
  final Dio _dio;

  HomeApi(this._dio);

  /// 获取活跃 Banner
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await _dio.get(ApiConstants.bannersActive);
      final data = response.data;
      final list = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data']
          : data;
      if (list is List) {
        return list
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
