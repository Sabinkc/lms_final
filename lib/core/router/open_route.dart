import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

extension OpenRoute on BuildContext {
  /// Opens [route] from a shortcut or menu. A bottom-nav tab root is
  /// switched to with `go`, so the nav bar stays and Home is one tap away;
  /// pushing it would stack a bar-less copy over the shell with no way
  /// back. Anything else is pushed as a normal detail screen.
  void openRoute(String route) => AppRoutes.tabRoots.contains(route) ? go(route) : push(route);
}
