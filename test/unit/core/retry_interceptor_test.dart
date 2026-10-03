import 'dart:typed_data';

import 'package:cloud_lms/core/network/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_client_adapter.dart';

/// Drops the connection for the first [failures] calls (the way Dio's real
/// adapter reports it, with the request attached), then answers 200.
class _FlakyAdapter implements HttpClientAdapter {
  final int failures;
  int calls = 0;

  _FlakyAdapter(this.failures);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    if (calls <= failures) throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    return jsonResponseBody({'ok': true}, 200);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))..httpClientAdapter = adapter;
  return dio..interceptors.add(RetryInterceptor(dio, delay: Duration.zero));
}

void main() {
  test('a GET whose connection drops once is retried and succeeds', () async {
    final adapter = _FlakyAdapter(1);

    final response = await _dioWith(adapter).get<dynamic>('/notices');

    expect(response.data, {'ok': true});
    expect(adapter.calls, 2);
  });

  test('a GET is retried only once', () async {
    final adapter = _FlakyAdapter(5);

    await expectLater(_dioWith(adapter).get<dynamic>('/notices'), throwsA(isA<DioException>()));
    expect(adapter.calls, 2);
  });

  test('a POST is never retried, so nothing is submitted twice', () async {
    final adapter = _FlakyAdapter(5);

    await expectLater(_dioWith(adapter).post<dynamic>('/fees', data: {'amount': 1}), throwsA(isA<DioException>()));
    expect(adapter.calls, 1);
  });

  test('a server error response is not retried', () async {
    final adapter = FakeHttpClientAdapter()..when('/notices', (_) => jsonResponseBody({'message': 'boom'}, 500));

    await expectLater(_dioWith(adapter).get<dynamic>('/notices'), throwsA(isA<DioException>()));
    expect(adapter.callCounts['/notices'], 1);
  });
}
