package com.yicai.trade.module.buyer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BuyerResponse {
    private Long id;
    private Long userId;
    private String companyName;
    private String contactPerson;
    private String contactPhone;
    private String address;
    private String industry;
    private String description;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
