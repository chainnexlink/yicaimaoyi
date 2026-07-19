package com.yicai.trade.module.order.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.order.dto.OrderCreateRequest;
import com.yicai.trade.module.order.dto.OrderResponse;
import com.yicai.trade.module.order.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Tag(name = "OrderManagement", description = "订单管理（完整交易闭环）")
public class OrderController {

    private final OrderService orderService;
    private final ResourceAuthorizationService authorizationService;

    @PostMapping
    @Operation(summary = "创建订单")
    public Result<OrderResponse> createOrder(@RequestParam Long buyerId,
                                             @RequestBody @Valid OrderCreateRequest request) {
        authorizationService.assertBuyerAccess(buyerId);
        return Result.success(orderService.createOrder(buyerId, request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取订单详情")
    public Result<OrderResponse> getOrder(@PathVariable Long id) {
        authorizationService.assertOrderAccess(id);
        return Result.success(orderService.getOrder(id));
    }

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "采购商订单列表")
    public Result<PageResult<OrderResponse>> listBuyerOrders(
            @PathVariable Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        authorizationService.assertBuyerAccess(buyerId);
        return Result.success(orderService.listBuyerOrders(buyerId, page, size));
    }

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "供应商订单列表")
    public Result<PageResult<OrderResponse>> listSupplierOrders(
            @PathVariable Long supplierId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        authorizationService.assertSupplierAccess(supplierId);
        return Result.success(orderService.listSupplierOrders(supplierId, page, size));
    }

    @PutMapping("/{id}/status")
    @Operation(summary = "更新订单状态（通用）")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        orderService.updateOrderStatus(id, body.get("status"),
                body.get("operatorId") != null ? Long.parseLong(body.get("operatorId")) : null,
                body.get("remark"));
        return Result.success();
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "取消订单", description = "仅PENDING状态可取消")
    public Result<Void> cancelOrder(@PathVariable Long id, @RequestParam Long operatorId) {
        authorizationService.assertOrderAccess(id);
        orderService.cancelOrder(id, operatorId);
        return Result.success();
    }

    // ===== 交易闭环操作 =====

    @PostMapping("/{id}/confirm")
    @Operation(summary = "供应商确认订单", description = "PENDING → CONFIRMED")
    public Result<Void> confirmOrder(
            @PathVariable Long id,
            @RequestParam Long supplierId,
            @RequestParam(required = false) String estimatedDeliveryDate) {
        authorizationService.assertSupplierAccess(supplierId);
        authorizationService.assertOrderAccess(id);
        LocalDate date = (estimatedDeliveryDate != null && !estimatedDeliveryDate.isBlank())
                ? LocalDate.parse(estimatedDeliveryDate) : null;
        orderService.confirmOrder(id, supplierId, date);
        return Result.success();
    }

    @PostMapping("/{id}/pay")
    @Operation(summary = "创建订单支付单", description = "创建待支付记录；订单仅在支付机构确认后变为 PAID")
    public Result<Void> confirmPayment(
            @PathVariable Long id,
            @RequestParam Long buyerId,
            @RequestParam String paymentMethod) {
        authorizationService.assertBuyerAccess(buyerId);
        authorizationService.assertOrderAccess(id);
        orderService.confirmPayment(id, buyerId, paymentMethod);
        return Result.success();
    }

    @PostMapping("/{id}/ship")
    @Operation(summary = "供应商发货", description = "PAID → SHIPPED")
    public Result<Void> shipOrder(
            @PathVariable Long id,
            @RequestParam Long supplierId,
            @RequestParam String trackingNumber,
            @RequestParam(required = false) String logisticsCompany) {
        authorizationService.assertSupplierAccess(supplierId);
        authorizationService.assertOrderAccess(id);
        orderService.shipOrder(id, supplierId, trackingNumber, logisticsCompany);
        return Result.success();
    }

    @PostMapping("/{id}/receipt")
    @Operation(summary = "采购商确认收货", description = "SHIPPED → RECEIVED")
    public Result<Void> confirmReceipt(
            @PathVariable Long id,
            @RequestParam Long buyerId) {
        authorizationService.assertBuyerAccess(buyerId);
        authorizationService.assertOrderAccess(id);
        orderService.confirmReceipt(id, buyerId);
        return Result.success();
    }

    @PostMapping("/{id}/complete")
    @Operation(summary = "完成订单", description = "RECEIVED → COMPLETED，联动完成关联合同")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> completeOrder(
            @PathVariable Long id,
            @RequestParam Long operatorId) {
        orderService.completeOrder(id, operatorId);
        return Result.success();
    }
}
