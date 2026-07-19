package com.yicai.trade.module.logistics.dto;

import lombok.Data;

@Data
public class TrackingQueryRequest {
    /** 快递单号 */
    private String trackingNo;
    /** 快递公司编码（可选，支持自动识别） */
    private String carrierCode;
}
