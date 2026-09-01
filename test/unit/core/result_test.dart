import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success carries data and reports isSuccess', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
    });

    test('Failure carries an AppException and reports isFailure', () {
      const result = Result<int>.failure(NetworkException());

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.dataOrNull, isNull);
    });

    test('when() dispatches to the matching branch exactly once', () {
      const success = Result<String>.success('ok');
      const failure = Result<String>.failure(ServerException());

      final successOutcome = success.when(success: (d) => 'got:$d', failure: (_) => 'fail');
      final failureOutcome = failure.when(success: (d) => 'got:$d', failure: (e) => 'fail:${e.message}');

      expect(successOutcome, 'got:ok');
      expect(failureOutcome, contains('fail:'));
    });
  });
}
