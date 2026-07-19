package com.yicai.trade.module.message.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MessageResponse {
    private Long id;
    private String messageNo;
    private String type;
    private String title;
    private String content;
    private Long senderId;
    private String senderName;
    private Long receiverId;
    private String receiverName;
    private Boolean isRead;
    private LocalDateTime readTime;
    private Long relatedId;
    private String relatedType;
    private String status;
    private LocalDateTime createdAt;
}
