import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/network/api_constants.dart';
import 'package:flutter_wasilah_app/core/network/api_interceptor.dart';
import 'package:flutter_wasilah_app/core/storage/secure_storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    ApiInterceptor(
      secureStorageService: ref.read(secureStorageServiceProvider),
    ),
  );

  return dio;
});
