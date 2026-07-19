package com.yicai.trade.module.order.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_order")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "order_no", nullable = false, unique = true, length = 50)
    private String orderNo;

    @NonNull
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @NonNull
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "total_amount", precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(nullable = false, length = 3)
    @Builder.Default
    private String currency = "USD";

    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";
    
    @Column(name = "payment_status", length = 20)
    @Builder.Default
    private String paymentStatus = "UNPAID";
    
    @Column(name = "payment_method", length = 50)
    private String paymentMethod;

    @Column(name = "shipping_address", length = 500)
    private String shippingAddress;

    @Column(name = "contact_person", length = 50)
    private String contactPerson;

    @Column(name = "contact_phone", length = 20)
    private String contactPhone;
    
    @Column(name = "required_delivery_date")
    private java.time.LocalDate requiredDeliveryDate;
    
    @Column(name = "estimated_delivery_date")
    private java.time.LocalDate estimatedDeliveryDate;
    
    @Column(name = "actual_delivery_date")
    private java.time.LocalDate actualDeliveryDate;
    
    @Column(name = "tracking_number", length = 100)
    private String trackingNumber;
    
    @Column(name = "logistics_company", length = 100)
    private String logisticsCompany;
    
    @Column(name = "contract_url", length = 255)
    private String contractUrl;
    
    @Column(name = "invoice_url", length = 255)
    private String invoiceUrl;

    @Column(length = 1000)
    private String remark;

    @Column(name = "contract_review_status", length = 20)
    private String contractReviewStatus;

    @NonNull
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
