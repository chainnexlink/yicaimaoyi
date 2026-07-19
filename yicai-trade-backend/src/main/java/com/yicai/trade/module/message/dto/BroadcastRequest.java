package com.yicai.trade.module.message.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.util.List;

@Data
public class BroadcastRequest {
    @NotBlank(message = "标题不能为空")
    private String title;
    private String content;
    private List<Long> receiverIds;  // null or empty = all users
    private String targetType;  // ALL, BUYERS, SUPPLIERS
}
