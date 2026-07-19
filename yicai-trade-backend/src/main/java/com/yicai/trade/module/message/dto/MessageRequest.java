package com.yicai.trade.module.message.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class MessageRequest {
    @NotBlank(message = "标题不能为空")
    private String title;
    private String content;
    private String type = "SYSTEM";
    private Long receiverId;
    private String receiverName;
    private Long relatedId;
    private String relatedType;
}
