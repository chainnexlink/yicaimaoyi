package com.yicai.trade.module.review.entity;

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
@Table(name = "t_order_review")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class OrderReview {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id")
    private Long orderId;

    @Column(name = "order_no", length = 50)
    private String orderNo;

    @Column(name = "buyer_id")
    private Long buyerId;

    @Column(name = "buyer_name", length = 100)
    private String buyerName;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "overall_rating")
    private Integer overallRating; // 1-5

    @Column(name = "quality_rating")
    private Integer qualityRating; // 1-5

    @Column(name = "delivery_rating")
    private Integer deliveryRating; // 1-5

    @Column(name = "service_rating")
    private Integer serviceRating; // 1-5

    @Column(name = "price_rating")
    private Integer priceRating; // 1-5

    @Column(name = "content", length = 2000)
    private String content;

    @Column(name = "image_urls", length = 2000)
    private String imageUrls; // JSON array

    @Column(name = "is_anonymous")
    @Builder.Default
    private Boolean isAnonymous = false;

    @Column(name = "supplier_reply", length = 1000)
    private String supplierReply;

    @Column(name = "replied_at")
    private LocalDateTime repliedAt;

    @Column(length = 20)
    @Builder.Default
    private String status = "PUBLISHED"; // PUBLISHED, HIDDEN, APPEALED

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
