package com.yicai.trade.module.membership.service;

import com.yicai.trade.module.membership.dto.PointsLogResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;

public interface PointsService {

    /** 支付成功后根据订单金额发放积分 */
    void earnPointsForOrder(Long userId, Long orderId, BigDecimal orderAmount);

    /** 退款后扣减已发放积分 */
    void deductPointsForRefund(Long userId, Long orderId, BigDecimal refundAmount);

    /** 查询用户积分流水 */
    Page<PointsLogResponse> getPointsHistory(Long userId, Pageable pageable);
}
