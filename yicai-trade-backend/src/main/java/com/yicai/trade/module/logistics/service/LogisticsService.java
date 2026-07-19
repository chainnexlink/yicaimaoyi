package com.yicai.trade.module.logistics.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.logistics.dto.*;
import java.util.Map;

public interface LogisticsService {
    LogisticsResponse create(LogisticsRequest request);
    LogisticsResponse getById(Long id);
    LogisticsResponse getByTrackingNo(String trackingNo);
    PageResult<LogisticsResponse> list(String status, int page, int size);
    void updateStatus(Long id, String status);
    Map<String, Long> getStats();

    /**
     * 实时查询快递物流轨迹（调用第三方API）
     *
     * @param trackingNo  快递单号
     * @param carrierCode 快递公司编码（可选）
     * @return 物流轨迹信息
     */
    TrackingQueryResponse queryTracking(String trackingNo, String carrierCode);
}
