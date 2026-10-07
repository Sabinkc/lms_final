import 'app_exception.dart';

/// Every repository method returns `Future<Result<T>>` rather than throwing
/// across the data → presentation boundary (docs/architecture.md §8). This
/// forces every provider to handle failure explicitly instead of relying on
/// try/catch discipline, and keeps [AppException] as the only failure type
/// presentation code ever sees.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Pattern-matching helper — prefer this over manual `is` checks so a
  /// future third [Result] subtype (there isn't one planned) would be a
  /// compile error here instead of a silently-skipped case at call sites.
  R when<R>({required R Function(T data) success, required R Function(AppException error) failure}) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(error: final error) => failure(error),
    };
  }

  /// Returns the success value or `null` — useful in widget code that just
  /// wants to display data and let a provider's own error state handle the
  /// failure path instead of branching twice.
  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}
