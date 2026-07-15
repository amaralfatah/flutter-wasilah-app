import 'dart:io';

import 'package:dio/dio.dart';

enum ApiExceptionType {
  connectionTimeout,
  noInternet,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.type, [this.message]);

  final ApiExceptionType type;
  final String? message;

  factory ApiException.fromDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(ApiExceptionType.connectionTimeout);
    }

    if (error.error is SocketException) {
      return const ApiException(ApiExceptionType.noInternet);
    }

    switch (error.response?.statusCode) {
      case 401:
        return const ApiException(ApiExceptionType.unauthorized);
      case 403:
        return const ApiException(ApiExceptionType.forbidden);
      case 404:
        return const ApiException(ApiExceptionType.notFound);
      case 500:
      case 502:
      case 503:
        return const ApiException(ApiExceptionType.serverError);
      default:
        return ApiException(ApiExceptionType.unknown, error.message);
    }
  }

  String get userMessage {
    switch (type) {
      case ApiExceptionType.connectionTimeout:
      case ApiExceptionType.noInternet:
        return 'Data belum dapat dimuat.\nPeriksa koneksi Anda dan coba kembali.';
      case ApiExceptionType.unauthorized:
        return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      case ApiExceptionType.forbidden:
        return 'Anda tidak memiliki akses untuk membuka data ini.';
      case ApiExceptionType.notFound:
        return 'Data yang Anda cari tidak ditemukan.';
      case ApiExceptionType.serverError:
        return 'Server sedang bermasalah. Coba lagi beberapa saat.';
      case ApiExceptionType.unknown:
        return message ?? 'Terjadi kesalahan yang belum dikenali.';
    }
  }

  @override
  String toString() => userMessage;
}
