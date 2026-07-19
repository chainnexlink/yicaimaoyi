package com.yicai.trade.module.thirdparty.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ThirdPartyConfigUpdateRequest {
    private String apiUrl;
    private String appKey;
    private String appSecret;
    private String appCode;
    private String extraConfig;
    private Boolean enabled;
    private Integer totalQuota;
    private LocalDateTime expiresAt;
    private String remark;
}
