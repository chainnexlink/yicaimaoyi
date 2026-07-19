package com.yicai.trade.module.shop.dto;

import lombok.Data;

@Data
public class ShopCreateRequest {
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
}
