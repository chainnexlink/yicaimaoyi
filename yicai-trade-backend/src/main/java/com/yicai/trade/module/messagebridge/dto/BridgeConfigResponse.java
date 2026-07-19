package com.yicai.trade.module.messagebridge.dto;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class BridgeConfigResponse {
    private boolean serviceEnabled;
    private BigDecimal monthlyPrice;
    private int trialDays;
    private int maxForwardPerDay;
    private String wechatWorkCorpId;
    private String wechatWorkAgentId;
    private String qqBotAppId;
}
