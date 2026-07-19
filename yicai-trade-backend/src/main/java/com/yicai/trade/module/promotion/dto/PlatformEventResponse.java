package com.yicai.trade.module.promotion.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class PlatformEventResponse {
    private Long id;
    private String eventName;
    private String eventType;
    private String description;
    private String bannerUrl;
    private String rules;
    private Integer maxParticipants;
    private Integer currentParticipants;
    private LocalDateTime signupStart;
    private LocalDateTime signupEnd;
    private LocalDateTime eventStart;
    private LocalDateTime eventEnd;
    private String status;
    private LocalDateTime createdAt;
}
