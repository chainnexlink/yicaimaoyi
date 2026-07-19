package com.yicai.trade.module.shop.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class ShopDashboardResponse {
    private Long totalPageViews;
    private Long totalOrders;
    private BigDecimal totalOrderAmount;
    private Long totalInquiries;
    private List<DailyStat> dailyStats;

    @Data
    public static class DailyStat {
        private String date;
        private int pageViews;
        private int uniqueVisitors;
        private int inquiryCount;
        private int orderCount;
        private BigDecimal orderAmount;
    }
}
