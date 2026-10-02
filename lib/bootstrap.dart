import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/service_locator.dart';
import 'core/logging/app_logger.dart';

/// Shared startup path for every entrypoint (`main_dev.dart`,
/// `main_staging.dart`, `main_prod.dart`). Centralizing this means the
/// three flavors can never drift on error-handling/DI/logging setup — only
/// on which [EnvConfig] they pass in.
Future<void> bootstrap(EnvConfig env) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      AppLogger.init(verbose: env.enableLogging);
      AppLogger.info('Starting CloudsLMS', env);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error('Flutter framework error', details.exception, details.stack);
      };
      // In release builds a widget that fails to build would otherwise show
      // as a blank grey box; show a short, friendly note instead.
      if (kReleaseMode) {
        ErrorWidget.builder = (_) => const Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Something went wrong showing this. Pull down to refresh or go back.', textAlign: TextAlign.center),
            ),
          ),
        );
      }

      await setupServiceLocator(env);

      runApp(const CloudsLmsApp());
    },
    (error, stackTrace) {
      AppLogger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
