package com.yicai.trade.module.certification.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.certification.dto.FactoryAuditRequest;
import com.yicai.trade.module.certification.dto.FactoryAuditResponse;

public interface FactoryAuditService {
    FactoryAuditResponse schedule(FactoryAuditRequest request);
    FactoryAuditResponse getById(Long id);
    PageResult<FactoryAuditResponse> list(String status, Long supplierId, int page, int size);
    void startAudit(Long id);
    void submitResult(Long id, String auditItems, String photos, Integer overallScore, String conclusion);
    void pass(Long id);
    void fail(Long id, String reason);
}
