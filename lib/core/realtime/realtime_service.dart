import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';
import '../logging/app_logger.dart';

/// Confirmed real-time transport (docs/api_spec.md §7/§9): Socket.IO,
/// scoped **only** to Chat's `group:*` events — there is no real-time
/// channel for Notifications or any other module (full-repo grep on the
/// backend found zero Socket.IO usage outside the chat socket handlers).
/// Do not route notification/attendance/etc. events through this service;
/// those stay plain polled REST calls in their own repositories.
///
/// Deliberately a thin connection-lifecycle wrapper only — no `group:*`
/// event handlers are wired here. Those belong to the Chat feature (not yet
/// built, per "no business features yet") and will subscribe/emit through
/// this shared connection rather than opening their own socket.
///
/// The JWT goes in the Socket.IO handshake's `auth` option
/// (`socket.handshake.auth.token` server-side), **not** a header — this is
/// intentionally a separate mechanism from [ApiClient]'s
/// [AuthInterceptor], matching how the backend actually authenticates a
/// socket connection.
abstract class RealtimeService {
  bool get isConnected;

  Future<void> connect(String accessToken);

  void disconnect();

  io.Socket get socket;
}

class SocketIoRealtimeService implements RealtimeService {
  final EnvConfig _env;
  io.Socket? _socket;

  SocketIoRealtimeService(this._env);

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  io.Socket get socket {
    final socket = _socket;
    if (socket == null) {
      throw StateError('RealtimeService.connect() must be called before accessing the socket.');
    }
    return socket;
  }

  @override
  Future<void> connect(String accessToken) async {
    _socket?.dispose();

    final socket = io.io(
      _env.baseUrl,
      io.OptionBuilder().setTransports(['websocket']).setAuth({'token': accessToken}).disableAutoConnect().build(),
    );

    socket.onConnect((_) => AppLogger.info('Socket connected'));
    socket.onDisconnect((_) => AppLogger.info('Socket disconnected'));
    socket.onConnectError((err) => AppLogger.warning('Socket connect error', err));

    _socket = socket;
    socket.connect();
  }

  @override
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
