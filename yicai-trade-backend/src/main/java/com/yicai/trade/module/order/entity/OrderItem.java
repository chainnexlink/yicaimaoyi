package com.yicai.trade.module.order.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_order_item")
@EqualsAndHashCode(of = {"id"})
@ToString(exclude = {"order"})
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "product_id")
    private Long productId;

    @Column(name = "product_name", length = 200)
    private String productName;

    @Column(name = "unit_price", precision = 12, scale = 2)
    private BigDecimal price;

    private Integer quantity;

    @Column(length = 20)
    private String unit;

    @Column(precision = 12, scale = 2)
    private BigDecimal subtotal;
}
