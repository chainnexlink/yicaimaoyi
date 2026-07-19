package com.yicai.trade.module.order.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@Schema(name = "OrderCreateRequest")
public class OrderCreateRequest {
    @NotNull(message = "supplierId required")
    private Long supplierId;
    private String shippingAddress;
    private String contactPhone;
    private String remark;
    @Pattern(regexp = "^[A-Za-z]{3}$", message = "currency must be a 3-letter ISO code")
    private String currency = "USD";
    private List<OrderItemRequest> items;

    @Data
    public static class OrderItemRequest {
        private Long productId;
        private String productName;
        private BigDecimal price;
        private Integer quantity;
        private String unit;
    }
}
