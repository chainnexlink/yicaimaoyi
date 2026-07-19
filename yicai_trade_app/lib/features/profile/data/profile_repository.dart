import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/data/models/user_info.dart';

/// 用户资料仓库 - 匹配后端 UserProfileController
class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  /// 获取当前用户资料: GET /api/user/profile
  Future<UserInfo> getProfile() async {
    final r = await _dio.get(ApiConstants.userProfile);
    return UserInfo.fromJson(_unwrap(r.data));
  }

  /// 更新用户资料: PUT /api/user/profile
  Future<UserInfo> updateProfile(Map<String, dynamic> data) async {
    final r = await _dio.put(ApiConstants.userProfile, data: data);
    return UserInfo.fromJson(_unwrap(r.data));
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['data'] is Map<String, dynamic> ? data['data'] : data;
    }
    return {};
  }
}
