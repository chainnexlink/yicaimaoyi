package com.yicai.trade.module.order.task;

import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 订单定时任务：未支付自动取消、未确认收货自动完成、支付提醒
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderScheduledTask {

    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final MessageService messageService;

    /**
     * 每30分钟扫描，将超过48小时未支付的PENDING订单自动取消。
     * 使用 orderService.updateOrderStatus() 确保写入 OrderStatusLog 审计日志。
     */
    @Scheduled(fixedDelay = 30 * 60 * 1000, initialDelay = 3 * 60 * 1000)
    public void autoCancelUnpaidOrders() {
        LocalDateTime cutoff = LocalDateTime.now().minusHours(48);
        List<Order> unpaidList = orderRepository.findByStatusAndCreatedAtBefore("PENDING", cutoff);

        if (unpaidList.isEmpty()) {
            return;
        }

        log.info("定时任务：发现 {} 笔超48h未支付订单，开始自动取消", unpaidList.size());

        for (Order order : unpaidList) {
            try {
                orderService.updateOrderStatus(order.getId(), "CANCELLED", 0L,
                        "系统自动取消：超过48小时未支付");

                messageService.sendSystemNotification(order.getBuyerId(),
                        "ORDER", "订单已自动取消",
                        "您的订单 " + order.getOrderNo() + " 因超过48小时未支付，已被系统自动取消。",
                        order.getId(), null);
                messageService.sendSystemNotification(order.getSupplierId(),
                        "ORDER", "订单已自动取消",
                        "订单 " + order.getOrderNo() + " 因买家超时未支付，已被系统自动取消。",
                        order.getId(), null);

                log.info("订单已自动取消: orderNo={}, createdAt={}", order.getOrderNo(), order.getCreatedAt());
            } catch (Exception e) {
                log.error("自动取消订单失败: orderId={}, error={}", order.getId(), e.getMessage());
            }
        }
    }

    /**
     * 每12小时扫描一次，对超过24小时但未到48小时的未支付订单发送提醒（避免重复轰炸）。
     */
    @Scheduled(fixedDelay = 12 * 60 * 60 * 1000, initialDelay = 5 * 60 * 1000)
    public void sendUnpaidReminders() {
        LocalDateTime cutoff24h = LocalDateTime.now().minusHours(24);
        LocalDateTime cutoff48h = LocalDateTime.now().minusHours(48);

        List<Order> remindList = orderRepository.findByStatusAndCreatedAtBefore("PENDING", cutoff24h);

        int sent = 0;
        for (Order order : remindList) {
            if (order.getCreatedAt() != null && order.getCreatedAt().isBefore(cutoff48h)) {
                continue; // 已超48h，即将被自动取消，不再提醒
            }
            try {
                messageService.sendSystemNotification(order.getBuyerId(),
                        "ORDER", "支付提醒",
                        "您的订单 " + order.getOrderNo() + " 尚未支付，请在48小时内完成支付，否则将被系统自动取消。",
                        order.getId(), null);
                sent++;
            } catch (Exception e) {
                log.warn("支付提醒发送失败: orderId={}", order.getId());
            }
        }
        if (sent > 0) {
            log.info("定时任务：已发送 {} 条未支付订单提醒", sent);
        }
    }

    /**
     * 每小时扫描，将超过15天已发货(SHIPPED)但买家未确认收货的订单自动完成。
     * 正确状态流转：SHIPPED → RECEIVED（系统代确认收货）→ COMPLETED（订单完成）。
     */
    @Scheduled(fixedDelay = 60 * 60 * 1000, initialDelay = 4 * 60 * 1000)
    public void autoCompleteUnconfirmedOrders() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(15);
        List<Order> unconfirmedList = orderRepository.findByStatusAndUpdatedAtBefore("SHIPPED", cutoff);

        if (unconfirmedList.isEmpty()) {
            return;
        }

        log.info("定时任务：发现 {} 笔超15天未确认收货订单，开始自动完成", unconfirmedList.size());

        for (Order order : unconfirmedList) {
            try {
                // 第一步：SHIPPED → RECEIVED，设置实际交付日期
                order.setActualDeliveryDate(LocalDate.now());
                orderRepository.save(order);
                orderService.updateOrderStatus(order.getId(), "RECEIVED", 0L,
                        "系统自动确认收货：超过15天买家未操作");

                // 第二步：RECEIVED → COMPLETED（触发完整的完成流程：资金释放、信用评分等）
                orderService.completeOrder(order.getId(), 0L);

                log.info("订单已自动完成: orderNo={}", order.getOrderNo());
            } catch (Exception e) {
                log.error("自动完成订单失败: orderId={}, error={}", order.getId(), e.getMessage());
            }
        }
    }
}
