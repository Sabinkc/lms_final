import 'package:logger/logger.dart';

/// Single logging entry point — nothing else in the app should call
/// `print()` or construct its own [Logger]. Wrapping the package behind a
/// static facade means swapping log backends later (e.g. shipping errors to
/// a crash-reporting service) is a one-file change.
class AppLogger {
  AppLogger._();

  static Logger? _instance;

  /// Must be called once during bootstrap (see `lib/bootstrap.dart`) before
  /// any log call — kept explicit rather than lazily-initialized so a
  /// missing call fails loudly in debug instead of silently no-op-ing.
  static void init({required bool verbose}) {
    _instance = Logger(
      level: verbose ? Level.trace : Level.warning,
      printer: PrettyPrinter(
        methodCount: verbose ? 2 : 0,
        errorMethodCount: 8,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  static Logger get _log {
    final instance = _instance;
    assert(instance != null, 'AppLogger.init() was never called.');
    return instance ?? Logger(level: Level.warning);
  }

  static void debug(String message, [Object? data]) => _log.d(_withData(message, data));

  static void info(String message, [Object? data]) => _log.i(_withData(message, data));

  static void warning(String message, [Object? data]) => _log.w(_withData(message, data));

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log.e(message, error: error, stackTrace: stackTrace);

  static String _withData(String message, Object? data) => data == null ? message : '$message | $data';
}
