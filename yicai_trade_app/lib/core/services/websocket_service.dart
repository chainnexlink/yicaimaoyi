import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:dio/dio.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart';

/// WebSocket 服务 - 封装 STOMP 协议连接
/// 用于竞价实时出价等场景
class WebSocketService {
  final Dio _dio;
  StompClient? _stompClient;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  StompUnsubscribe? _unsubscribe;
  bool _isConnected = false;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  WebSocketService(this._dio);

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// 连接到指定 topic (e.g. /topic/auction/123)
  void connect(String topic, {String? pollUrl}) {
    _reconnectAttempts = 0;

    try {
      final wsUrl =
          '${ApiConstants.baseUrl}${ApiConstants.wsEndpoint}/websocket';

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,
          onConnect: (frame) {
            _isConnected = true;
            _reconnectAttempts = 0;
            _stopPolling();
            _subscribe(topic);
          },
          onDisconnect: (frame) {
            _isConnected = false;
            _attemptReconnect(topic, pollUrl: pollUrl);
          },
          onWebSocketError: (error) {
            _isConnected = false;
            _startPolling(pollUrl);
          },
          onStompError: (frame) {
            _isConnected = false;
            _startPolling(pollUrl);
          },
        ),
      );
      _stompClient!.activate();
    } catch (e) {
      // WebSocket 不可用，回退到轮询
      _startPolling(pollUrl);
    }
  }

  void _subscribe(String topic) {
    _unsubscribe?.call();
    _unsubscribe = _stompClient?.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (_) {}
        }
      },
    );
  }

  void _attemptReconnect(String topic, {String? pollUrl}) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _startPolling(pollUrl);
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect(topic, pollUrl: pollUrl));
  }

  /// 回退到 HTTP 轮询 (10秒间隔)
  void _startPolling(String? pollUrl) {
    if (pollUrl == null || _pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final response = await _dio.get(pollUrl);
        if (response.data != null) {
          final data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : <String, dynamic>{'data': response.data};
          _messageController.add(data);
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void disconnect() {
    _unsubscribe?.call();
    _unsubscribe = null;
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
    _stopPolling();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

/// WebSocket 服务的 Riverpod Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final dio = ref.watch(dioProvider);
  final service = WebSocketService(dio);
  ref.onDispose(() => service.dispose());
  return service;
});
