import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'models/certification_model.dart';

/// 认证仓库 - 对标网站 certification.html 的完整 API 操作
class CertificationRepository {
  final Dio _dio;
  CertificationRepository(this._dio);

  /// 获取当前用户的所有认证记录
  Future<List<CertificationModel>> getCertifications() async {
    final response = await _dio.get('${ApiConstants.apiPrefix}/certification');
    final data = response.data;
    final body = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    if (body is List) {
      return body
          .map((e) => CertificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取认证详情
  Future<CertificationModel> getDetail(int id) async {
    final response = await _dio.get(
      '${ApiConstants.apiPrefix}/certification/$id',
    );
    final data = response.data;
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    return CertificationModel.fromJson(body as Map<String, dynamic>);
  }

  /// 提交认证申请
  Future<CertificationModel> submitCertification(
    Map<String, dynamic> certData,
  ) async {
    final response = await _dio.post(
      '${ApiConstants.apiPrefix}/certification',
      data: certData,
    );
    final data = response.data;
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    return CertificationModel.fromJson(body as Map<String, dynamic>);
  }

  /// 上传认证文件 (营业执照、身份证等)
  Future<String> uploadCertFile(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      ApiConstants.certificationUpload,
      data: formData,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['data']?.toString() ?? data['url']?.toString() ?? '';
    }
    return '';
  }

  /// 获取认证统计
  Future<CertificationStats> getStats() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.apiPrefix}/certification/stats',
      );
      final data = response.data;
      final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
      return CertificationStats.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return const CertificationStats();
    }
  }
}
