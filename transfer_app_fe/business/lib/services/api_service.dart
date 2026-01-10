import 'dart:typed_data';
import 'package:business/models/cloud/cloud_list_response_state.dart';
import 'package:business/models/signed_url_response.dart';
import 'package:dio/dio.dart';
import '../models/cloud/link_expiry.dart';
import 'dio_service.dart';

class ApiService {
  final Dio _dio = DioService().dio;

  Future<CloudListResponseState> getFiles() async {
    try {
      final response = await _dio.get(
        '/.netlify/functions/r2',
        queryParameters: {'action': 'list'},
        options: Options(headers: {'Authorization': 'Bearer 12345'}),
      );

      return CloudListResponseState.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception('Failed to fetch files: ${e.message}');
    }
  }

  Future<void> uploadFile(
    String filename,
    Uint8List bytes,
    LinkExpiry expiry,
  ) async {
    final response = await DioService().dio.get(
      '/.netlify/functions/r2',
      queryParameters: {
        'action': 'upload',
        'key': filename,
        'contentType': 'application/octet-stream',
        'expiresIn': expiry.seconds,
        'size': bytes.length,
      },
      options: Options(headers: {'Authorization': 'Bearer ${"12345"}'}),
    );

    final SignedUrlResponse signedUrlResponse = SignedUrlResponse.fromJson(
      response.data,
    );

    final uploadResponse = await Dio().put(
      signedUrlResponse.url,
      data: bytes,
      options: Options(headers: {'Content-Type': 'application/octet-stream'}),
    );
    if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
      print('Upload successful!');
    } else {
      throw Exception(
        'Upload failed: ${uploadResponse.statusCode} ${uploadResponse.data}',
      );
    }
  }

  Future<void> deleteFile(String filename) async {
    try {
      await _dio.delete('/files/$filename');
    } on DioException catch (e) {
      throw Exception('Delete failed: ${e.message}');
    }
  }

  Future<String> getDownloadUrl(String key, LinkExpiry expiry) async {
    final response = await DioService().dio.get(
      '/.netlify/functions/r2',
      queryParameters: {
        'action': 'download',
        'key': key,
        'expiresIn': expiry.seconds,
      },
    );

    final url = response.data['url'] as String;
    return url;
  }

  Future<List<Map<String, String>>> getDownloadUrlsForFolder(
    String folderKey,
    LinkExpiry expiry,
  ) async {
    final response = await DioService().dio.get(
      '/.netlify/functions/r2',
      queryParameters: {
        'action': 'download-folder',
        'key': folderKey,
        'expiresIn': expiry.seconds,
      },
    );

    final data = response.data['urls'] as List;
    // Each item: { key: String, url: String }
    return data
        .map((e) => {'key': e['key'] as String, 'url': e['url'] as String})
        .toList();
  }
}
