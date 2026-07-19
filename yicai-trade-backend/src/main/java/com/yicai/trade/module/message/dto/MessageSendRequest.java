package com.yicai.trade.module.message.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.NonNull;

@Data
public class MessageSendRequest {
    @NonNull
    @NotNull
    private Long receiverId;
    
    private String msgType;
    
    @NonNull
    @NotBlank
    private String title;
    
    private String content;
    
    private Long relatedId;
    
    private String relatedType;
}
