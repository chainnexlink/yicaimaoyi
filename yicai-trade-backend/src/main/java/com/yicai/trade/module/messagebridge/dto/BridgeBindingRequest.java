package com.yicai.trade.module.messagebridge.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BridgeBindingRequest {
    @NotBlank(message = "渠道类型不能为空")
    private String channelType;  // WECHAT_WORK / QQ_BOT
    @NotBlank(message = "渠道用户ID不能为空")
    private String channelUserId;
    private String channelUsername;
}
