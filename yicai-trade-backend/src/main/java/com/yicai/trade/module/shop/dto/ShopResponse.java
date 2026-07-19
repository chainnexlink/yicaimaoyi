package com.yicai.trade.module.shop.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ShopResponse {
    private Long id;
    private Long supplierId;
    private String shopName;
    private String shopLogo;
    private String shopBanner;
    private String shopDescription;
    private String mainProducts;
    private String industry;
    private String province;
    private String city;
    private String detailAddress;
    private String contactName;
    private String contactPhone;
    private String contactEmail;
    private String themeColor;
    private String customCss;
    private String sectionsConfig;
    private String seoTitle;
    private String seoKeywords;
    private String seoDescription;
    private Long visitCount;
    private Integer productCount;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
