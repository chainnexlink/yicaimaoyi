package com.yicai.trade.module.messagebridge.service;

import com.yicai.trade.module.messagebridge.dto.BridgeLogResponse;
import com.yicai.trade.module.messagebridge.dto.BridgeStatsResponse;

import java.util.List;

public interface BridgeForwardingService {
    void forwardMessage(Long messageId);
    void receiveExternalMessage(String channelType, String channelUserId, String content);
    List<BridgeLogResponse> getSupplierLogs(Long supplierId, int page, int size);
    List<BridgeLogResponse> getAllLogs(int page, int size);
    BridgeStatsResponse getStats();
}
