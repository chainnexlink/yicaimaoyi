package com.yicai.trade.module.demand.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class DemandResponse {
    private Long id;
    private String demandNo;
    private Long buyerId;
    private String buyerCompanyName;
    private String title;
    private String description;
    private String categoryCode;
    private String categoryName;
    private Integer quantity;
    private String unit;
    private BigDecimal budget;
    private Integer expectedDeliveryDays;
    private Integer responseCount;
    private Integer viewCount;
    private String status;
    private String auditStatus;
    private String auditRemark;
    private LocalDateTime auditTime;
    private LocalDateTime expireTime;
    private LocalDateTime createdAt;
}
