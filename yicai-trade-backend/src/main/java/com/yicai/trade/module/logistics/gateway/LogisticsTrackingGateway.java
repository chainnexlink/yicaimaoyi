package com.yicai.trade.module.logistics.gateway;

import com.yicai.trade.module.logistics.dto.TrackingQueryResponse;

/**
 * 物流轨迹查询网关接口
 */
public interface LogisticsTrackingGateway {

    /**
     * 查询快递物流轨迹
     *
     * @param trackingNo  快递单号
     * @param carrierCode 快递公司编码（可选，支持自动识别）
     * @return 物流轨迹查询结果
     */
    TrackingQueryResponse queryTracking(String trackingNo, String carrierCode);
}
