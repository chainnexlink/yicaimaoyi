package com.yicai.trade.module.review.dto;

import lombok.Data;

@Data
public class ReviewSummaryResponse {
    private Long supplierId;
    private long totalReviews;
    private double avgOverallRating;
    private double avgQualityRating;
    private double avgDeliveryRating;
}
