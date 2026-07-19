package com.yicai.trade.module.logistics.dto;

import lombok.Data;
import java.util.List;

@Data
public class TrackingQueryResponse {
    /** 快递单号 */
    private String trackingNo;
    /** 快递公司编码 */
    private String carrierCode;
    /** 快递公司名称 */
    private String carrierName;
    /** 物流轨迹列表（按时间倒序） */
    private List<TrackNode> tracks;
    /** 投递状态: 0=快递收件/揽件, 1=在途, 2=正在派件, 3=已签收, 4=退签/退回 */
    private String deliveryStatus;
    /** 是否签收: 0=未签收, 1=已签收 */
    private String signed;
    /** 查询是否成功 */
    private boolean success;
    /** 错误信息 */
    private String errorMsg;

    @Data
    public static class TrackNode {
        /** 节点时间 */
        private String time;
        /** 节点描述 */
        private String status;
    }
}
