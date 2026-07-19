package com.yicai.trade.module.messagebridge.dto;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class BridgeStatsResponse {
    private long activeSubscriptions;
    private long totalSubscriptions;
    private BigDecimal totalRevenue;
    private long todayForwards;
    private long totalForwards;
    private long boundUsers;
    private long wechatForwards;
    private long qqForwards;
    private long successCount;
    private long failedCount;
}
