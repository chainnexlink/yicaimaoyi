package com.yicai.trade.module.inquiry.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InquiryResponse {
    private Long id;
    private Long buyerId;
    private String title;
    private String description;
    private String productCategory;
    private Integer expectedQuantity;
    private String unit;
    private String status;
    private LocalDateTime deadline;
    private List<QuotationResponse> quotations;
    private LocalDateTime createdAt;
}
