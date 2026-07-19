package com.yicai.trade.module.dispute.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.dispute.dto.DisputeCreateRequest;
import com.yicai.trade.module.dispute.dto.DisputeResponse;

import java.math.BigDecimal;
import java.util.Map;

public interface DisputeService {
    DisputeResponse create(DisputeCreateRequest request);
    DisputeResponse getById(Long id);
    PageResult<DisputeResponse> list(String status, String disputeType, Long assignedTo, int page, int size);
    void assignTo(Long disputeId, Long staffId);
    void startReview(Long disputeId, Long operatorId);
    void startMediation(Long disputeId, Long operatorId, String message);
    void makeRuling(Long disputeId, Long operatorId, String rulingType, BigDecimal awardedAmount, String reason);
    void enforce(Long disputeId, Long operatorId);
    void close(Long disputeId, Long operatorId, String remark);
    void withdraw(Long disputeId, Long operatorId, String reason);
    void addMessage(Long disputeId, Long senderId, String senderRole, String content, String attachmentUrls);
    Map<String, Long> getStats();
}
