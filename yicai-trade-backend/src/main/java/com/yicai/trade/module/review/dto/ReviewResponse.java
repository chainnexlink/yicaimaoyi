package com.yicai.trade.module.review.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ReviewResponse {
    private Long id;
    private Long orderId;
    private String orderNo;
    private Long buyerId;
    private String buyerName;
    private Long supplierId;
    private Integer overallRating;
    private Integer qualityRating;
    private Integer deliveryRating;
    private Integer serviceRating;
    private Integer priceRating;
    private String content;
    private String imageUrls;
    private Boolean isAnonymous;
    private String supplierReply;
    private LocalDateTime repliedAt;
    private String status;
    private LocalDateTime createdAt;
}
