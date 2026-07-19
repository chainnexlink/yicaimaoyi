package com.yicai.trade.module.messagebridge.service;

import com.yicai.trade.module.messagebridge.dto.BridgeSubscriptionRequest;
import com.yicai.trade.module.messagebridge.dto.BridgeSubscriptionResponse;
import com.yicai.trade.module.messagebridge.dto.BridgeStatusResponse;

import java.util.List;

public interface BridgeSubscriptionService {
    BridgeSubscriptionResponse subscribe(Long userId, Long supplierId, BridgeSubscriptionRequest request);
    BridgeSubscriptionResponse activateSubscription(Long subscriptionId);
    void cancelSubscription(Long subscriptionId, Long userId);
    boolean hasActiveSubscription(Long supplierId, String channelType);
    BridgeStatusResponse getSupplierStatus(Long supplierId);
    BridgeSubscriptionResponse renewSubscription(Long subscriptionId, Long userId);
    List<BridgeSubscriptionResponse> listSupplierSubscriptions(Long supplierId, int page, int size);
    List<BridgeSubscriptionResponse> listAllSubscriptions(String status, int page, int size);
    void expireOverdueSubscriptions();
    void sendExpiryReminders();
}
