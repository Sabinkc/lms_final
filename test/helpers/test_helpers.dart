import 'package:flutter/material.dart';

/// Thin wrapper so widget tests don't each repeat `MaterialApp(home: ...)`
/// boilerplate. Add a `MultiProvider` wrapper variant here once a test
/// needs to pump a widget that reads a feature provider via context.
Widget wrapWithMaterialApp(Widget child) => MaterialApp(home: child);
