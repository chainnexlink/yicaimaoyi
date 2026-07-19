package com.yicai.trade.module.aftersale.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.aftersale.dto.AftersaleCreateRequest;
import com.yicai.trade.module.aftersale.dto.AftersaleResponse;

import java.util.Map;

public interface AftersaleService {
    AftersaleResponse create(AftersaleCreateRequest request);
    AftersaleResponse getById(Long id);
    PageResult<AftersaleResponse> list(String status, String type, Long buyerId, Long supplierId, int page, int size);
    void supplierApprove(Long id, Long operatorId, String remark);
    void supplierReject(Long id, Long operatorId, String remark);
    void buyerShipReturn(Long id, Long operatorId, String trackingNo, String carrier);
    void supplierConfirmReceive(Long id, Long operatorId);
    void executeRefund(Long id, Long operatorId);
    void executeExchange(Long id, Long operatorId, String trackingNo, String carrier);
    void complete(Long id, Long operatorId);
    void buyerAppeal(Long id, Long operatorId, String reason);
    void platformIntervene(Long id, Long operatorId, String decision, String remark);
    Map<String, Long> getStats();
}
