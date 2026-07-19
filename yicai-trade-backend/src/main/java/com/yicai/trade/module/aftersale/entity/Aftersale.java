package com.yicai.trade.module.aftersale.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_aftersale")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Aftersale {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "aftersale_no", unique = true, length = 50)
    private String aftersaleNo;

    @Column(name = "order_id")
    private Long orderId;

    @Column(name = "order_no", length = 50)
    private String orderNo;

    @Column(name = "buyer_id")
    private Long buyerId;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "type", length = 20)
    private String type; // RETURN, EXCHANGE, REPAIR, REFUND_ONLY

    @Column(name = "reason_type", length = 50)
    private String reasonType; // QUALITY, WRONG_ITEM, DAMAGED, MISSING, SPEC_MISMATCH, OTHER

    @Column(name = "reason", length = 1000)
    private String reason;

    @Column(name = "evidence_urls", length = 2000)
    private String evidenceUrls; // JSON array of image/file URLs

    @Column(name = "refund_amount", precision = 14, scale = 2)
    private BigDecimal refundAmount;

    @Column(name = "return_tracking_no", length = 50)
    private String returnTrackingNo;

    @Column(name = "return_carrier", length = 50)
    private String returnCarrier;

    @Column(name = "exchange_tracking_no", length = 50)
    private String exchangeTrackingNo;

    @Column(name = "exchange_carrier", length = 50)
    private String exchangeCarrier;

    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";
    // PENDING -> SUPPLIER_APPROVED -> BUYER_SHIPPED -> SUPPLIER_RECEIVED
    // -> REFUNDED / EXCHANGED / REPAIRED / COMPLETED
    // or PENDING -> REJECTED -> (APPEAL -> PLATFORM_INTERVENE -> RESOLVED)

    @Column(name = "supplier_remark", length = 1000)
    private String supplierRemark;

    @Column(name = "platform_remark", length = 1000)
    private String platformRemark;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
