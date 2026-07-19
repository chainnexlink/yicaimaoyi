package com.yicai.trade.module.payment.event;

import com.yicai.trade.module.membership.service.PointsService;
import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.wallet.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
public class PaymentEventListener {

    private final PointsService pointsService;
    private final MessageService messageService;
    private final OrderRepository orderRepository;
    private final ContractRepository contractRepository;
    private final WalletService walletService;

    @Async
    @EventListener
    public void onPaymentSuccess(PaymentSuccessEvent event) {
        // 1. 积分奖励
        try {
            pointsService.earnPointsForOrder(event.getPayerId(), event.getOrderId(), event.getAmount());
            log.info("支付成功-积分奖励完成: paymentId={}, orderId={}", event.getPaymentId(), event.getOrderId());
        } catch (Exception e) {
            log.error("支付成功-积分奖励失败: paymentId={}, error={}", event.getPaymentId(), e.getMessage(), e);
        }

        // 2. 确保佣金记录存在（如果有关联合同）
        try {
            if (event.getOrderId() != null) {
                Optional<Order> orderOpt = orderRepository.findById(event.getOrderId());
                if (orderOpt.isPresent()) {
                    // 查找关联合同
                    Optional<Contract> contractOpt = contractRepository.findAll().stream()
                            .filter(c -> event.getOrderId().equals(c.getOrderId()))
                            .findFirst();
                    if (contractOpt.isPresent()) {
                        Long contractId = contractOpt.get().getId();
                        walletService.ensureCommission(contractId, new BigDecimal("0.01"));
                        log.info("支付成功-佣金记录已确保: paymentId={}, contractId={}", event.getPaymentId(), contractId);
                    }
                }
            }
        } catch (Exception e) {
            log.error("支付成功-佣金记录创建失败: paymentId={}, error={}", event.getPaymentId(), e.getMessage(), e);
        }

        // 3. 消息通知
        try {
            if (event.getOrderId() != null) {
                Optional<Order> orderOpt = orderRepository.findById(event.getOrderId());
                if (orderOpt.isPresent()) {
                    Order order = orderOpt.get();
                    messageService.sendSystemNotification(event.getPayerId(),
                            "ORDER", "支付成功",
                            "您的订单 " + order.getOrderNo() + " 已支付成功，金额 ¥" + event.getAmount(),
                            event.getOrderId(), "ORDER");
                }
            }
        } catch (Exception e) {
            log.error("支付成功-消息通知失败: paymentId={}, error={}", event.getPaymentId(), e.getMessage(), e);
        }
    }

    @Async
    @EventListener
    public void onRefundSuccess(RefundSuccessEvent event) {
        // 1. 积分扣减
        try {
            pointsService.deductPointsForRefund(event.getApplicantId(), event.getOrderId(), event.getRefundAmount());
            log.info("退款成功-积分扣减完成: refundId={}, orderId={}", event.getRefundId(), event.getOrderId());
        } catch (Exception e) {
            log.error("退款成功-积分扣减失败: refundId={}, error={}", event.getRefundId(), e.getMessage(), e);
        }

        // 2. 消息通知
        try {
            if (event.getOrderId() != null) {
                Optional<Order> orderOpt = orderRepository.findById(event.getOrderId());
                if (orderOpt.isPresent()) {
                    Order order = orderOpt.get();
                    messageService.sendSystemNotification(event.getApplicantId(),
                            "ORDER", "退款已到账",
                            "您的订单 " + order.getOrderNo() + " 退款 ¥" + event.getRefundAmount() + " 已处理完成。",
                            event.getOrderId(), "ORDER");
                }
            }
        } catch (Exception e) {
            log.error("退款成功-消息通知失败: refundId={}, error={}", event.getRefundId(), e.getMessage(), e);
        }
    }
}
