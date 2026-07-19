package com.yicai.trade.module.content.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IndustryResponse {
    private Long id;
    private String name;
    private String nameEn;
    private Integer sortOrder;
    private String status;
    private LocalDateTime createdAt;
}
