package com.yicai.trade.module.inquiry.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.NonNull;

import java.time.LocalDateTime;

@Data
public class InquiryCreateRequest {
    @NonNull
    @NotBlank
    private String title;
    
    private String description;
    
    private String productCategory;
    
    @NonNull
    @NotNull
    private Integer expectedQuantity;
    
    private String unit;
    
    private LocalDateTime deadline;
}
