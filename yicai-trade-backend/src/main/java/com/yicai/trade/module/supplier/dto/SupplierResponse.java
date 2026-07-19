package com.yicai.trade.module.supplier.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierResponse {
    private Long id;
    private Long userId;
    private String companyName;
    private String contactPerson;
    private String contactPhone;
    private String businessLicense;
    private String address;
    private String description;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    // User 关联信息
    private String username;
    private String email;
    private String phone;
}
