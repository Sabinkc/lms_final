import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// No real network per docs/production_roadmap.md Phase A step 5 — routes
/// are matched by path, each returning a canned response registered with
/// [when]. [callCounts] lets a test assert exactly how many times a given
/// endpoint was hit (needed for single-flight-style assertions).
class FakeHttpClientAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(int callNumber)> _handlers = {};
  final Map<String, int> callCounts = {};

  void when(String path, ResponseBody Function(int callNumber) handler) => _handlers[path] = handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final handler = _handlers[options.path];
    if (handler == null) {
      throw StateError('FakeHttpClientAdapter: no response registered for ${options.path}');
    }
    final callNumber = (callCounts[options.path] ?? 0) + 1;
    callCounts[options.path] = callNumber;
    return handler(callNumber);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponseBody(Object data, int statusCode) => ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// For endpoints hit with `Options(responseType: ResponseType.bytes)` (Excel
/// export/template downloads, docs/api_spec.md §4.2) — a raw binary body,
/// not a JSON envelope.
ResponseBody bytesResponseBody(List<int> bytes, int statusCode) => ResponseBody.fromBytes(bytes, statusCode);
