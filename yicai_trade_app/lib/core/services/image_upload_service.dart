import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart';

/// 图片上传服务 - 用于智能匹配的产品图片上传
class ImageUploadService {
  final Dio _dio;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService(this._dio);

  /// 从相机拍照
  Future<String?> pickFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;
    return _uploadImage(image.path);
  }

  /// 从图库选择
  Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;
    return _uploadImage(image.path);
  }

  /// 上传图片到后端，返回 imageUrl
  Future<String> _uploadImage(String filePath) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/upload/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['data']?['url'] ?? data['url'] ?? '';
      }
      return '';
    } catch (e) {
      rethrow;
    }
  }
}

/// ImageUploadService Riverpod Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return ImageUploadService(dio);
});
