package com.yicai.trade.module.comment.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class CommentResponse {
    private Long id;
    private Long userId;
    private String userName;
    private String sourceType;
    private Long sourceId;
    private String content;
    private Integer rating;
    private String status;
    private LocalDateTime createdAt;
}
