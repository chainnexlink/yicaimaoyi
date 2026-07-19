package com.yicai.trade.module.logistics.entity;

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
@Table(name = "t_logistics")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Logistics {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tracking_no", unique = true, length = 50)
    private String trackingNo;

    @Column(name = "order_id")
    private Long orderId;

    @Column(name = "order_no", length = 30)
    private String orderNo;

    @Column(name = "sender_name", length = 100)
    private String senderName;

    @Column(name = "sender_address", length = 500)
    private String senderAddress;

    @Column(name = "receiver_name", length = 100)
    private String receiverName;

    @Column(name = "receiver_address", length = 500)
    private String receiverAddress;

    @Column(length = 50)
    private String carrier;

    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING"; // PENDING, SHIPPING, DELIVERED, EXCEPTION

    @Column(name = "shipped_at")
    private LocalDateTime shippedAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    @Column(length = 500)
    private String remark;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
