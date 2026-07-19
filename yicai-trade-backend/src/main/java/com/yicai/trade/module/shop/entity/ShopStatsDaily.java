package com.yicai.trade.module.shop.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_shop_stats_daily")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class ShopStatsDaily {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "shop_id")
    private Long shopId;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "stat_date")
    private LocalDate statDate;

    @Column(name = "page_views")
    @Builder.Default
    private Integer pageViews = 0;

    @Column(name = "unique_visitors")
    @Builder.Default
    private Integer uniqueVisitors = 0;

    @Column(name = "inquiry_count")
    @Builder.Default
    private Integer inquiryCount = 0;

    @Column(name = "order_count")
    @Builder.Default
    private Integer orderCount = 0;

    @Column(name = "order_amount", precision = 14, scale = 2)
    @Builder.Default
    private java.math.BigDecimal orderAmount = java.math.BigDecimal.ZERO;

    @Column(name = "product_click_count")
    @Builder.Default
    private Integer productClickCount = 0;

    @Column(name = "favorite_count")
    @Builder.Default
    private Integer favoriteCount = 0;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
