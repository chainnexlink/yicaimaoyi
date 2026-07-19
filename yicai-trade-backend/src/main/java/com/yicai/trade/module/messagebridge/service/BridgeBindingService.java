package com.yicai.trade.module.messagebridge.service;

import com.yicai.trade.module.messagebridge.dto.BridgeBindingRequest;
import com.yicai.trade.module.messagebridge.dto.BridgeBindingResponse;

import java.util.List;

public interface BridgeBindingService {
    BridgeBindingResponse bind(Long userId, Long supplierId, BridgeBindingRequest request);
    BridgeBindingResponse verify(Long userId, String channelType, String verificationCode);
    void unbind(Long userId, String channelType);
    List<BridgeBindingResponse> getBindings(Long supplierId);
    BridgeBindingResponse getBinding(Long supplierId, String channelType);
}
