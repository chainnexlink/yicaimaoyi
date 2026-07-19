package com.yicai.trade.module.auction.event;

import com.yicai.trade.module.auction.service.AuctionService;
import com.yicai.trade.module.order.event.OrderStatusChangedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * 拍卖模块监听订单状态变更事件
 * 当订单状态变化时，同步更新关联的拍卖状态。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuctionOrderEventListener {

    private final AuctionService auctionService;

    @Async
    @EventListener
    public void onOrderStatusChanged(OrderStatusChangedEvent event) {
        try {
            auctionService.syncAuctionStatusFromOrder(event.getOrderId(), event.getToStatus());
            log.debug("拍卖模块处理订单状态变更: orderId={}, {} → {}",
                    event.getOrderId(), event.getFromStatus(), event.getToStatus());
        } catch (Exception e) {
            log.warn("拍卖模块同步订单状态失败: orderId={}, toStatus={}, error={}",
                    event.getOrderId(), event.getToStatus(), e.getMessage());
        }
    }
}
