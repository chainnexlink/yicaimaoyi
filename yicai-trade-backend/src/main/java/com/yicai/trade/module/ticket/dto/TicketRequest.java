package com.yicai.trade.module.ticket.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class TicketRequest {
    private Long userId;
    private String userName;
    @NotBlank(message = "工单类型不能为空")
    private String ticketType;
    @NotBlank(message = "标题不能为空")
    private String title;
    private String content;
    private String priority;
}
