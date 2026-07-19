import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/auction_model.dart';

// WebSocket 消息类型
enum AuctionMessageType {
  bidUpdate,
  statusUpdate,
  extension,
  unknown,
}

// WebSocket 消息
class AuctionWsMessage {
  final AuctionMessageType type;
  final Map<String, dynamic> raw;

  AuctionWsMessage({required this.type, required this.raw});

  factory AuctionWsMessage.fromMap(Map<String, dynamic> data) {
    final typeStr = data['type']?.toString() ?? '';
    AuctionMessageType type;
    switch (typeStr) {
      case 'BID_UPDATE':
        type = AuctionMessageType.bidUpdate;
        break;
      case 'AUCTION_STATUS_UPDATE':
      case 'STATUS_UPDATE':
        type = AuctionMessageType.statusUpdate;
        break;
      case 'EXTENSION':
      case 'TIME_EXTENSION':
        type = AuctionMessageType.extension;
        break;
      default:
        type = AuctionMessageType.unknown;
    }
    return AuctionWsMessage(type: type, raw: data);
  }

  // 解析出价更新
  BidModel? get bid {
    if (type != AuctionMessageType.bidUpdate) return null;
    final bidData = raw['bid'] ?? raw['data'] ?? raw;
    if (bidData is Map<String, dynamic>) {
      return BidModel.fromJson(bidData);
    }
    return null;
  }

  // 解析新状态
  String? get newStatus => raw['newStatus'] ?? raw['status'];

  // 解析新结束时间 (延时用)
  DateTime? get newEndTime {
    final t = raw['newEndTime'] ?? raw['endTime'];
    if (t == null) return null;
    return DateTime.tryParse(t.toString());
  }

  // 当前最低价
  double? get currentLowest {
    final v = raw['currentLowest'] ?? raw['currentLowestPrice'];
    if (v == null) return null;
    return (v as num).toDouble();
  }
}

// 竞价实时消息流 Provider (按 auctionId)
final auctionWsProvider =
    StreamProvider.family<AuctionWsMessage, int>((ref, auctionId) {
  final wsService = ref.watch(webSocketServiceProvider);
  final topic = '/topic/auction/$auctionId';
  final pollUrl = '${ApiConstants.auctionBase}/$auctionId/bids';

  wsService.connect(topic, pollUrl: pollUrl);

  ref.onDispose(() {
    wsService.disconnect();
  });

  return wsService.messages.map((data) => AuctionWsMessage.fromMap(data));
});
