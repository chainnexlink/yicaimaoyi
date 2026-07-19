package com.yicai.trade.module.membership.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class MembershipResponse {
    private Long id;
    private Long userId;
    private String userName;
    private String companyName;
    private String level;
    private Integer points;
    private Integer totalPoints;
    private LocalDateTime expireAt;
    private LocalDateTime createdAt;
}
