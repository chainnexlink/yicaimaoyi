package com.yicai.trade.module.ticket.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class TicketResponse {
    private Long id;
    private String ticketNo;
    private Long userId;
    private String userName;
    private String ticketType;
    private String title;
    private String content;
    private String priority;
    private String status;
    private String replyContent;
    private LocalDateTime repliedAt;
    private LocalDateTime createdAt;
}
