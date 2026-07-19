package com.yicai.trade.module.shop.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_shop")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Shop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", unique = true)
    private Long supplierId;

    @Column(name = "shop_name", length = 200)
    private String shopName;

    @Column(name = "shop_logo", length = 500)
    private String shopLogo;

    @Column(name = "shop_banner", length = 500)
    private String shopBanner;

    @Column(name = "shop_description", length = 2000)
    private String shopDescription;

    @Column(name = "main_products", length = 500)
    private String mainProducts;

    @Column(name = "industry", length = 100)
    private String industry;

    @Column(name = "province", length = 50)
    private String province;

    @Column(name = "city", length = 50)
    private String city;

    @Column(name = "detail_address", length = 500)
    private String detailAddress;

    @Column(name = "contact_name", length = 50)
    private String contactName;

    @Column(name = "contact_phone", length = 30)
    private String contactPhone;

    @Column(name = "contact_email", length = 100)
    private String contactEmail;

    @Column(name = "theme_color", length = 20)
    @Builder.Default
    private String themeColor = "#1a73e8";

    @Column(name = "custom_css", length = 5000)
    private String customCss;

    @Column(name = "sections_config", columnDefinition = "TEXT")
    private String sectionsConfig; // JSON: shop page sections layout config

    @Column(name = "seo_title", length = 200)
    private String seoTitle;

    @Column(name = "seo_keywords", length = 500)
    private String seoKeywords;

    @Column(name = "seo_description", length = 500)
    private String seoDescription;

    @Column(name = "visit_count")
    @Builder.Default
    private Long visitCount = 0L;

    @Column(name = "product_count")
    @Builder.Default
    private Integer productCount = 0;

    @Column(length = 20)
    @Builder.Default
    private String status = "ACTIVE"; // ACTIVE, SUSPENDED, CLOSED

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
