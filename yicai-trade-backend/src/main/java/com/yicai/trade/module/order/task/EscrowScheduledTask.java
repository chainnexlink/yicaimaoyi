package com.yicai.trade.module.order.task;

import com.yicai.trade.module.order.service.EscrowService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 托管资金定时任务：自动释放到期且已完成订单的托管资金
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EscrowScheduledTask {

    private final EscrowService escrowService;

    /**
     * 每30分钟扫描一次，释放所有到期的已完成订单托管资金
     */
    @Scheduled(fixedDelay = 30 * 60 * 1000, initialDelay = 2 * 60 * 1000)
    public void autoReleaseExpiredEscrows() {
        try {
            int count = escrowService.autoReleaseExpiredEscrows();
            if (count > 0) {
                log.info("定时任务：自动释放 {} 笔到期托管资金", count);
            }
        } catch (Exception e) {
            log.error("定时任务：自动释放托管异常", e);
        }
    }
}
