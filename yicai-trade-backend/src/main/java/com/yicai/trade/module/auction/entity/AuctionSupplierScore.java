package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 供应商综合评分
 * 支持按价格/交期/质量/服务多维度加权评分
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_supplier_score", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"auction_id", "supplier_id"})
})
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionSupplierScore {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 拍卖ID */
    @Column(name = "auction_id", nullable = false)
    private Long auctionId;

    /** 供应商ID */
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 供应商名称 */
    @Column(name = "supplier_company", length = 200)
    private String supplierCompany;

    /** 价格得分（自动计算） */
    @Column(name = "price_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal priceScore = BigDecimal.ZERO;

    /** 交期得分 */
    @Column(name = "delivery_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal deliveryScore = BigDecimal.ZERO;

    /** 质量得分 */
    @Column(name = "quality_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal qualityScore = BigDecimal.ZERO;

    /** 服务得分 */
    @Column(name = "service_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal serviceScore = BigDecimal.ZERO;

    /** 综合得分 */
    @Column(name = "total_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal totalScore = BigDecimal.ZERO;

    /** 综合排名 */
    @Column(name = "ranking")
    private Integer ranking;

    /** 评分人ID */
    @Column(name = "scored_by")
    private Long scoredBy;

    /** 评分时间 */
    @Column(name = "scored_at")
    private LocalDateTime scoredAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
