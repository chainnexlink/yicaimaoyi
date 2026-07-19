package com.yicai.trade.module.order.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.order.dto.OrderCreateRequest;
import com.yicai.trade.module.order.dto.OrderResponse;

public interface OrderService {
    OrderResponse createOrder(Long buyerId, OrderCreateRequest request);
    OrderResponse getOrder(Long orderId);
    PageResult<OrderResponse> listBuyerOrders(Long buyerId, int page, int size);
    PageResult<OrderResponse> listSupplierOrders(Long supplierId, int page, int size);
    void updateOrderStatus(Long orderId, String status, Long operatorId, String remark);
    void cancelOrder(Long orderId, Long operatorId);

    /** 供应商确认订单 */
    void confirmOrder(Long orderId, Long supplierId, java.time.LocalDate estimatedDeliveryDate);

    /** 采购商付款确认 */
    void confirmPayment(Long orderId, Long buyerId, String paymentMethod);

    /** 供应商发货 */
    void shipOrder(Long orderId, Long supplierId, String trackingNumber, String logisticsCompany);

    /** 采购商确认收货 */
    void confirmReceipt(Long orderId, Long buyerId);

    /** 完成订单（联动合同完成） */
    void completeOrder(Long orderId, Long operatorId);
}
