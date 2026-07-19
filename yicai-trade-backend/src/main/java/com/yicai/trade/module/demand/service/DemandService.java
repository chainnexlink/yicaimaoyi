package com.yicai.trade.module.demand.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.demand.dto.*;

public interface DemandService {
    DemandResponse createDemand(Long buyerId, DemandRequest request);
    DemandResponse updateDemand(Long id, DemandRequest request);
    void deleteDemand(Long id);
    DemandResponse getDemand(Long id);
    DemandResponse getDemandByNo(String demandNo);
    PageResult<DemandResponse> listDemands(String status, String category, int page, int size);
    PageResult<DemandResponse> listBuyerDemands(Long buyerId, int page, int size);
    PageResult<DemandResponse> listPendingAudit(int page, int size);
    void approveDemand(Long id, Long auditorId);
    void rejectDemand(Long id, Long auditorId, String reason);
    void closeDemand(Long id);
    void incrementResponseCount(Long id);
    void incrementViewCount(Long id);
}
