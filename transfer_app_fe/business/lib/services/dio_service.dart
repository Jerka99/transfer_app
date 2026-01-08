import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioService {
  static final DioService _instance = DioService._internal();

  factory DioService() => _instance;

  final Dio _dio;

  DioService._internal()
      : _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8888",
      headers: {'Content-Type': 'application/json'},
      // connectTimeout: const Duration(seconds: 10),
      // receiveTimeout: const Duration(seconds: 10),
    ),
  ) {

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(responseBody: true),
      ); // Only in debug mode
    }
    // dio.interceptors.add(LogInterceptor(
    //   request: true,
    //   requestHeader: true,
    //   responseHeader: true,
    //   responseBody: false, // Set to true if you want to log response bodies
    // ));

    // _dio.interceptors.add(
    //   InterceptorsWrapper(
    //     onRequest: (options, handler) async {
    //       // String? token = await JwtService().readTokenFromSecureStorage(
    //       //   key: "access_token",
    //       // );
    //       // if (token != null) {
    //       //   options.headers['Authorization'] = 'Bearer $token';
    //       // }
    //       // final languageId = StorageService().readPref(key: 'language_id');todo add after be fix
    //       // if (languageId != null) {
    //       //   options.queryParameters['languageId'] = languageId;
    //       // }
    //
    //       return handler.next(options);
    //     },
    //   ),
    // );
  }

  Dio get dio => _dio;
}
