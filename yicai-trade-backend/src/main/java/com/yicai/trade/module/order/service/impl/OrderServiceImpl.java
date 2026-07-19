package com.yicai.trade.module.order.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.order.dto.OrderCreateRequest;
import com.yicai.trade.module.order.dto.OrderResponse;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.entity.OrderItem;
import com.yicai.trade.module.order.entity.OrderStatusLog;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.order.repository.OrderStatusLogRepository;
import com.yicai.trade.module.order.service.OrderService;
import com.yicai.trade.module.order.service.EscrowService;
import com.yicai.trade.module.payment.dto.PaymentCreateRequest;
import com.yicai.trade.module.payment.dto.PaymentResponse;
import com.yicai.trade.module.payment.service.PaymentService;
import com.yicai.trade.module.wallet.service.WalletService;
import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.order.event.OrderStatusChangedEvent;
import com.yicai.trade.module.score.service.SupplierCreditService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepository;
    private final OrderStatusLogRepository statusLogRepository;
    private final ContractRepository contractRepository;
    private final BuyerRepository buyerRepository;
    private final PaymentService paymentService;
    private final EscrowService escrowService;
    private final WalletService walletService;
    private final MessageService messageService;
    private final SupplierCreditService creditService;
    private final ApplicationEventPublisher eventPublisher;

    @Override
    @Transactional
    @SuppressWarnings("null")
    public OrderResponse createOrder(Long buyerId, OrderCreateRequest request) {
        @lombok.NonNull Order order = Order.builder()
                .orderNo(generateOrderNo()).buyerId(buyerId)
                .supplierId(request.getSupplierId())
                .currency(normalizeCurrency(request.getCurrency()))
                .shippingAddress(request.getShippingAddress())
                .contactPhone(request.getContactPhone())
                .remark(request.getRemark()).status("PENDING").build();
        if (request.getItems() != null) {
            BigDecimal total = BigDecimal.ZERO;
            for (OrderCreateRequest.OrderItemRequest ir : request.getItems()) {
                BigDecimal sub = ir.getPrice().multiply(BigDecimal.valueOf(ir.getQuantity()));
                @lombok.NonNull OrderItem item = OrderItem.builder()
                        .order(order).productId(ir.getProductId())
                        .productName(ir.getProductName()).price(ir.getPrice())
                        .quantity(ir.getQuantity()).unit(ir.getUnit()).subtotal(sub).build();
                order.getItems().add(item);
                total = total.add(sub);
            }
            order.setTotalAmount(total);
        }
        return toResponse(orderRepository.save(order));
    }

    @Override
    @SuppressWarnings("null")
    public OrderResponse getOrder(@lombok.NonNull Long orderId) {
        return toResponse(orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND)));
    }

    @Override
    public PageResult<OrderResponse> listBuyerOrders(Long buyerId, int page, int size) {
        Page<Order> orders = orderRepository.findByBuyerId(buyerId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(orders.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                orders.getTotalElements(), page, size);
    }

    @Override
    public PageResult<OrderResponse> listSupplierOrders(Long supplierId, int page, int size) {
        Page<Order> orders = orderRepository.findBySupplierId(supplierId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(orders.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                orders.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void updateOrderStatus(Long orderId, String status, Long operatorId, String remark) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        String from = order.getStatus();
        order.setStatus(status);
        orderRepository.save(order);
        @lombok.NonNull OrderStatusLog log = OrderStatusLog.builder()
                .orderId(orderId).fromStatus(from).toStatus(status)
                .operatorId(operatorId).remark(remark).build();
        statusLogRepository.save(log);

        // 发布订单状态变更事件，供拍卖等模块监听同步
        try {
            eventPublisher.publishEvent(
                    new OrderStatusChangedEvent(this, orderId, from, status, operatorId));
        } catch (Exception e) {
            OrderServiceImpl.log.warn("发布订单状态变更事件失败: orderId={}, status={}, error={}",
                    orderId, status, e.getMessage());
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void cancelOrder(Long orderId, Long operatorId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        if (!"PENDING".equals(order.getStatus()) && !"CONFIRMED".equals(order.getStatus())) {
            throw new BusinessException(ErrorCode.ORDER_CANNOT_CANCEL);
        }
        updateOrderStatus(orderId, "CANCELLED", operatorId, "订单取消");

        // 通知供应商订单已取消
        try {
            messageService.sendSystemNotification(order.getSupplierId(),
                    "ORDER", "订单已取消",
                    "订单 " + order.getOrderNo() + " 已被取消，请知悉。",
                    orderId, null);
        } catch (Exception e) {
            log.warn("订单取消通知供应商失败: orderId={}", orderId);
        }
    }

    // ===== 交易闭环新增方法 =====

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void confirmOrder(Long orderId, Long supplierId, LocalDate estimatedDeliveryDate) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        if (!order.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (!"PENDING".equals(order.getStatus())) {
            throw new BusinessException(ErrorCode.ORDER_STATUS_INVALID);
        }
        order.setEstimatedDeliveryDate(estimatedDeliveryDate);
        updateOrderStatus(orderId, "CONFIRMED", supplierId, "供应商确认订单");

        // 通知采购商
        try {
            messageService.sendSystemNotification(order.getBuyerId(),
                    "ORDER", "订单已确认",
                    "您的订单 " + order.getOrderNo() + " 已被供应商确认，预计交付日期：" + estimatedDeliveryDate,
                    orderId, null);
        } catch (Exception e) {
            log.warn("订单确认消息通知失败: orderId={}", orderId);
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void confirmPayment(Long orderId, Long buyerId, String paymentMethod) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        if (!order.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (!"CONFIRMED".equals(order.getStatus())) {
            throw new BusinessException(ErrorCode.ORDER_STATUS_INVALID);
        }

        // 仅创建支付记录；在线通道必须等待服务端验证后的支付机构结果。
        List<PaymentResponse> existingPayments = paymentService.getPaymentsByOrderId(orderId);
        PaymentResponse pendingPayment = existingPayments.stream()
                .filter(p -> "PENDING".equals(p.getStatus()) || "PROCESSING".equals(p.getStatus()))
                .findFirst().orElse(null);

        if (pendingPayment != null) {
            if (!pendingPayment.getPaymentMethod().equalsIgnoreCase(paymentMethod)) {
                throw new BusinessException(ErrorCode.PAYMENT_DUPLICATE, "订单已有其他通道的待支付记录");
            }
            log.info("订单已有待支付记录: orderId={}, paymentNo={}", orderId, pendingPayment.getPaymentNo());
        } else {
            PaymentCreateRequest payReq = new PaymentCreateRequest();
            payReq.setOrderId(orderId);
            payReq.setAmount(order.getTotalAmount());
            payReq.setPaymentMethod(paymentMethod);
            Long payerUserId = buyerRepository.findById(buyerId)
                    .orElseThrow(() -> new BusinessException(ErrorCode.BUYER_NOT_FOUND))
                    .getUserId();
            PaymentResponse created = paymentService.createPayment(payReq, payerUserId);
            log.info("订单支付单创建成功，等待支付机构确认: orderId={}, paymentNo={}",
                    orderId, created.getPaymentNo());
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void shipOrder(Long orderId, Long supplierId, String trackingNumber, String logisticsCompany) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        if (!order.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (!"PAID".equals(order.getStatus())) {
            throw new BusinessException(ErrorCode.ORDER_STATUS_INVALID);
        }
        order.setTrackingNumber(trackingNumber);
        order.setLogisticsCompany(logisticsCompany);
        orderRepository.save(order);
        updateOrderStatus(orderId, "SHIPPED", supplierId, "已发货，物流单号：" + trackingNumber);

        // 通知采购商
        try {
            messageService.sendSystemNotification(order.getBuyerId(),
                    "ORDER", "订单已发货",
                    "您的订单 " + order.getOrderNo() + " 已发货，物流公司：" + logisticsCompany + "，单号：" + trackingNumber,
                    orderId, null);
        } catch (Exception e) {
            log.warn("发货消息通知失败: orderId={}", orderId);
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void confirmReceipt(Long orderId, Long buyerId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        if (!order.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (!"SHIPPED".equals(order.getStatus())) {
            throw new BusinessException(ErrorCode.ORDER_STATUS_INVALID);
        }
        order.setActualDeliveryDate(LocalDate.now());
        orderRepository.save(order);
        updateOrderStatus(orderId, "RECEIVED", buyerId, "采购商确认收货");

        // 通知供应商
        try {
            messageService.sendSystemNotification(order.getSupplierId(),
                    "ORDER", "采购商已确认收货",
                    "订单 " + order.getOrderNo() + " 采购商已确认收货，等待订单完成后托管资金将释放到您的钱包。",
                    orderId, null);
        } catch (Exception e) {
            log.warn("确认收货消息通知失败: orderId={}", orderId);
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void completeOrder(Long orderId, Long operatorId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        if (!"RECEIVED".equals(order.getStatus())) {
            throw new BusinessException(ErrorCode.ORDER_STATUS_INVALID);
        }
        updateOrderStatus(orderId, "COMPLETED", operatorId, "订单完成");

        // 联动完成关联的合同，并获取合同ID用于佣金处理
        Long contractId = null;
        Optional<Contract> contractOpt = contractRepository.findAll().stream()
                .filter(c -> orderId.equals(c.getOrderId()) && "EXECUTING".equals(c.getStatus()))
                .findFirst();
        if (contractOpt.isPresent()) {
            Contract contract = contractOpt.get();
            contract.setStatus("COMPLETED");
            contractRepository.save(contract);
            contractId = contract.getId();
            log.info("订单完成，关联合同已完成: orderId={}, contractId={}", orderId, contractId);
        }

        // 释放托管资金到供应商
        try {
            escrowService.releaseEscrow(orderId);
            log.info("订单完成，托管资金已释放: orderId={}", orderId);
        } catch (Exception e) {
            log.warn("托管资金释放失败（需管理员手动处理）: orderId={}, error={}", orderId, e.getMessage());
        }

        // ===== 佣金闭环：收取平台服务费 + 执行返佣 =====
        if (contractId != null) {
            try {
                // 确保佣金记录存在（幂等），默认返佣 1%
                walletService.ensureCommission(contractId, new BigDecimal("0.01"));
                // 收取平台服务费（2%）
                walletService.collectServiceFee(contractId);
                log.info("平台服务费已收取: contractId={}", contractId);
                // 执行返佣到采购商零钱
                walletService.executeRebate(contractId);
                log.info("返佣已执行: contractId={}, buyerId={}", contractId, order.getBuyerId());
            } catch (Exception e) {
                log.warn("佣金处理异常（需管理员手动处理）: contractId={}, error={}", contractId, e.getMessage());
            }
        }

        // ===== 消息通知闭环 =====
        final Long finalContractId = contractId;
        try {
            messageService.sendSystemNotification(order.getBuyerId(),
                    "ORDER", "订单已完成",
                    "您的订单 " + order.getOrderNo() + " 已完成，托管资金已释放。" +
                    (finalContractId != null ? "返佣金额已入账您的零钱钱包。" : ""),
                    orderId, null);
            messageService.sendSystemNotification(order.getSupplierId(),
                    "ORDER", "订单已完成",
                    "订单 " + order.getOrderNo() + " 已完成，托管资金已到账您的零钱钱包。",
                    orderId, null);
        } catch (Exception e) {
            log.warn("订单完成消息通知失败: orderId={}, error={}", orderId, e.getMessage());
        }

        // ===== 供应商信用评分闭环 =====
        try {
            boolean onTime = order.getActualDeliveryDate() != null
                    && order.getEstimatedDeliveryDate() != null
                    && !order.getActualDeliveryDate().isAfter(order.getEstimatedDeliveryDate());
            creditService.onOrderCompleted(order.getSupplierId(), orderId, onTime);
            log.info("供应商信用评分已更新: orderId={}, supplierId={}, onTime={}", orderId, order.getSupplierId(), onTime);
        } catch (Exception e) {
            log.warn("供应商信用评分更新失败: orderId={}, error={}", orderId, e.getMessage());
        }

        // ===== 评价邀请通知 =====
        try {
            messageService.sendSystemNotification(order.getBuyerId(),
                    "REVIEW", "邀请您对订单进行评价",
                    "订单 " + order.getOrderNo() + " 已完成，请对供应商的质量、交付和服务进行评价，帮助其他买家做出更好的采购决策。",
                    orderId, null);
        } catch (Exception e) {
            log.warn("评价邀请通知发送失败: orderId={}", orderId);
        }
    }

    // ===== helpers =====

    private String generateOrderNo() {
        return "OD" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);
    }

    private OrderResponse toResponse(Order o) {
        List<OrderResponse.OrderItemResponse> items = null;
        if (o.getItems() != null) {
            items = o.getItems().stream().map(i -> OrderResponse.OrderItemResponse.builder()
                    .id(i.getId()).productId(i.getProductId()).productName(i.getProductName())
                    .price(i.getPrice()).quantity(i.getQuantity()).unit(i.getUnit())
                    .subtotal(i.getSubtotal()).build()).collect(Collectors.toList());
        }
        return OrderResponse.builder()
                .id(o.getId()).orderNo(o.getOrderNo()).buyerId(o.getBuyerId())
                .supplierId(o.getSupplierId()).totalAmount(o.getTotalAmount())
                .currency(o.getCurrency())
                .status(o.getStatus())
                .paymentStatus(o.getPaymentStatus())
                .paymentMethod(o.getPaymentMethod())
                .shippingAddress(o.getShippingAddress()).contactPhone(o.getContactPhone())
                .requiredDeliveryDate(o.getRequiredDeliveryDate())
                .estimatedDeliveryDate(o.getEstimatedDeliveryDate())
                .actualDeliveryDate(o.getActualDeliveryDate())
                .trackingNumber(o.getTrackingNumber())
                .logisticsCompany(o.getLogisticsCompany())
                .contractUrl(o.getContractUrl())
                .invoiceUrl(o.getInvoiceUrl())
                .remark(o.getRemark())
                .items(items).createdAt(o.getCreatedAt()).updatedAt(o.getUpdatedAt()).build();
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank() ? "USD" : currency.trim().toUpperCase(Locale.ROOT);
    }
}
