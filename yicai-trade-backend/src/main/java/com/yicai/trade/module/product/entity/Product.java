package com.yicai.trade.module.product.entity;

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
@Table(name = "t_product")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "product_no", unique = true, length = 30)
    private String productNo;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "supplier_name", length = 100)
    private String supplierName;

    @Column(length = 50)
    private String category;

    @Column(precision = 12, scale = 2)
    private BigDecimal price;

    @Column(name = "min_order_quantity")
    private Integer minOrderQuantity;

    @Column(length = 20)
    private String unit;

    private Integer stock;

    @Column(length = 1000)
    private String description;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "audit_status", length = 20)
    @Builder.Default
    private String auditStatus = "PENDING"; // PENDING, APPROVED, REJECTED

    @Column(name = "audit_remark", length = 500)
    private String auditRemark;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
