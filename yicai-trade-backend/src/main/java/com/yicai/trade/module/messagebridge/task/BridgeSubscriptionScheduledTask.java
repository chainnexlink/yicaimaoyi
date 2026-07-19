package com.yicai.trade.module.messagebridge.task;

import com.yicai.trade.module.messagebridge.service.BridgeSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class BridgeSubscriptionScheduledTask {

    private final BridgeSubscriptionService subscriptionService;

    /**
     * Check for expired subscriptions every hour
     */
    @Scheduled(fixedDelay = 3600000, initialDelay = 120000)
    public void expireOverdueSubscriptions() {
        try {
            log.info("Running bridge subscription expiry check...");
            subscriptionService.expireOverdueSubscriptions();
        } catch (Exception e) {
            log.error("Error in subscription expiry task: {}", e.getMessage(), e);
        }
    }

    /**
     * Send expiry reminders daily at 9am (check every 6 hours)
     */
    @Scheduled(fixedDelay = 21600000, initialDelay = 300000)
    public void sendExpiryReminders() {
        try {
            log.info("Running bridge subscription expiry reminder check...");
            subscriptionService.sendExpiryReminders();
        } catch (Exception e) {
            log.error("Error in subscription reminder task: {}", e.getMessage(), e);
        }
    }
}
