package com.yicai.trade.module.messagebridge.dto;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
public class BridgeStatusResponse {
    private boolean serviceEnabled;
    private String subscriptionStatus;  // NONE / ACTIVE / EXPIRED
    private LocalDate subscriptionEndDate;
    private Boolean autoRenew;
    private BigDecimal monthlyPrice;
    private List<BridgeBindingResponse> bindings;
}
