package com.yicai.trade.module.order.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {
    private Long id;
    private String orderNo;
    private Long buyerId;
    private Long supplierId;
    private BigDecimal totalAmount;
    private String currency;
    private String status;
    private String paymentStatus;
    private String paymentMethod;
    private String shippingAddress;
    private String contactPhone;
    private java.time.LocalDate requiredDeliveryDate;
    private java.time.LocalDate estimatedDeliveryDate;
    private java.time.LocalDate actualDeliveryDate;
    private String trackingNumber;
    private String logisticsCompany;
    private String contractUrl;
    private String invoiceUrl;
    private String remark;
    private List<OrderItemResponse> items;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OrderItemResponse {
        private Long id;
        private Long productId;
        private String productName;
        private BigDecimal price;
        private Integer quantity;
        private String unit;
        private BigDecimal subtotal;
    }
}
