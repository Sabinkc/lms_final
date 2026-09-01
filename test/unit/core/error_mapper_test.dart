import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapper = const ErrorMapper();
  final requestOptions = RequestOptions(path: '/test');

  group('ErrorMapper', () {
    test('maps a connection timeout to NetworkException', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      expect(mapper.map(error), isA<NetworkException>());
    });

    test('maps a 401 with a code field to UnauthorizedException, preserving the code', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Token expired', 'code': 'TOKEN_EXPIRED'},
        ),
      );

      final mapped = mapper.map(error);
      expect(mapped, isA<UnauthorizedException>());
      expect(mapped.code, 'TOKEN_EXPIRED');
    });

    test('maps a 401 with NO code field (protectAdmin-style) without throwing', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Not authorized'},
        ),
      );

      final mapped = mapper.map(error);
      expect(mapped, isA<UnauthorizedException>());
      expect(mapped.code, isNull);
    });

    test('reads {error} instead of {message} on the one debug-style envelope shape', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 500,
          data: {'error': 'debug failure'},
        ),
      );

      expect(mapper.map(error).message, 'debug failure');
    });

    test('maps a 5xx to ServerException', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: requestOptions, statusCode: 500, data: {}),
      );

      expect(mapper.map(error), isA<ServerException>());
    });

    test('passes an already-mapped AppException through unchanged', () {
      const original = ValidationException('bad input');
      expect(mapper.map(original), same(original));
    });
  });
}
