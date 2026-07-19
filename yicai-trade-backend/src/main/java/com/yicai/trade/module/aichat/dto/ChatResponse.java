package com.yicai.trade.module.aichat.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ChatResponse {
    private String sessionId;
    private String message;
    private String type;            // "text", "product_list", "factory_list", "cost_result", "auction_form", "order_status"
    private List<Map<String, Object>> data;
    private Map<String, Object> extra;
}
