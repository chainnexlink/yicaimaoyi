package com.yicai.trade.module.membership.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class PointsLogResponse {
    private Long id;
    private Long userId;
    private String changeType;
    private Integer changeAmount;
    private Integer balanceBefore;
    private Integer balanceAfter;
    private String sourceType;
    private Long sourceId;
    private String description;
    private LocalDateTime createdAt;
}
