package com.yicai.trade.module.thirdparty.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ThirdPartyConfigResponse {
    private Long id;
    private String configKey;
    private String configName;
    private String provider;
    private String apiUrl;
    private String appCode;
    private String appKey;
    private Boolean enabled;
    private Integer totalQuota;
    private Integer usedQuota;
    private LocalDateTime expiresAt;
    private String extraConfig;
    private String remark;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
