package com.yicai.trade.module.shop.dto;

import lombok.Data;

@Data
public class ShopDecorationRequest {
    private String shopBanner;
    private String themeColor;
    private String customCss;
    private String sectionsConfig;
    private String seoTitle;
    private String seoKeywords;
    private String seoDescription;
}
