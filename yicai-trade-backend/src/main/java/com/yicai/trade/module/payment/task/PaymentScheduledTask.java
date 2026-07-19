package com.yicai.trade.module.payment.task;

import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.payment.entity.Payment;
import com.yicai.trade.module.payment.entity.PaymentOperationLog;
import com.yicai.trade.module.payment.repository.PaymentOperationLogRepository;
import com.yicai.trade.module.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 支付定时任务：自动过期处理 & 状态同步
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PaymentScheduledTask {

    private final PaymentRepository paymentRepository;
    private final PaymentOperationLogRepository operationLogRepository;
    private final MessageService messageService;

    /**
     * 每5分钟扫描一次，将超过 expiredAt 的 PENDING/PROCESSING 支付自动标记为 EXPIRED，
     * 并通知付款人支付已失效。
     */
    @Scheduled(fixedDelay = 5 * 60 * 1000, initialDelay = 60 * 1000)
    @Transactional
    public void expireOverduePayments() {
        LocalDateTime now = LocalDateTime.now();
        List<Payment> overdueList = new java.util.ArrayList<>(paymentRepository
                .findByStatusAndExpiredAtBefore("PENDING", now));
        overdueList.addAll(paymentRepository.findByStatusAndExpiredAtBefore("PROCESSING", now));

        if (overdueList.isEmpty()) {
            return;
        }

        log.info("定时任务：发现 {} 笔超时支付，开始处理", overdueList.size());

        for (Payment payment : overdueList) {
            try {
                String fromStatus = payment.getStatus();
                payment.setStatus("EXPIRED");
                paymentRepository.save(payment);

                PaymentOperationLog logEntry = PaymentOperationLog.builder()
                        .paymentId(payment.getId())
                        .paymentNo(payment.getPaymentNo())
                        .operationType("EXPIRE")
                        .fromStatus(fromStatus)
                        .toStatus("EXPIRED")
                        .remark("定时任务自动过期")
                        .build();
                operationLogRepository.save(logEntry);

                // 通知付款人支付已失效
                if (payment.getPayerId() != null) {
                    messageService.sendSystemNotification(payment.getPayerId(),
                            "PAYMENT", "支付已过期",
                            "您的支付单 " + payment.getPaymentNo() + " 已超时未完成支付，已自动失效。如需继续，请重新发起支付。",
                            payment.getOrderId(), "ORDER");
                }

                log.info("支付已过期: paymentNo={}, expiredAt={}", payment.getPaymentNo(), payment.getExpiredAt());
            } catch (Exception e) {
                log.error("支付过期处理失败: paymentId={}, error={}", payment.getId(), e.getMessage());
            }
        }

        log.info("定时任务：超时支付处理完成，共 {} 笔", overdueList.size());
    }
}
