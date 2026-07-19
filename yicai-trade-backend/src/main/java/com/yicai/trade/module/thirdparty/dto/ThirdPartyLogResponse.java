package com.yicai.trade.module.thirdparty.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ThirdPartyLogResponse {
    private Long id;
    private String configKey;
    private String action;
    private String target;
    private Boolean success;
    private String errorMsg;
    private Integer costMs;
    private LocalDateTime createdAt;
}
