package com.yicai.trade.module.messagebridge.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BridgeSubscriptionRequest {
    @NotBlank(message = "渠道类型不能为空")
    private String channelType;  // WECHAT_WORK / QQ_BOT / ALL
    private String paymentMethod;  // ALIPAY / WECHAT / BANK_TRANSFER
    private Boolean autoRenew = false;
}
