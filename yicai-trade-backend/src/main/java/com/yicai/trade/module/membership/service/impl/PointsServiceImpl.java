package com.yicai.trade.module.membership.service.impl;

import com.yicai.trade.module.membership.dto.PointsLogResponse;
import com.yicai.trade.module.membership.entity.Membership;
import com.yicai.trade.module.membership.entity.PointsLog;
import com.yicai.trade.module.membership.repository.MembershipRepository;
import com.yicai.trade.module.membership.repository.PointsLogRepository;
import com.yicai.trade.module.membership.service.PointsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PointsServiceImpl implements PointsService {

    private final PointsLogRepository pointsLogRepository;
    private final MembershipRepository membershipRepository;

    /** 积分比例：每100元订单金额 = 1积分 */
    private static final BigDecimal POINTS_RATIO = new BigDecimal("100");

    @Override
    @Transactional
    public void earnPointsForOrder(Long userId, Long orderId, BigDecimal orderAmount) {
        // 幂等检查：已为该订单发过积分则跳过
        List<PointsLog> existing = pointsLogRepository.findByUserIdAndSourceTypeAndSourceId(userId, "ORDER", orderId);
        if (!existing.isEmpty()) {
            log.info("用户[{}]订单[{}]积分已发放，跳过", userId, orderId);
            return;
        }

        int points = orderAmount.divide(POINTS_RATIO, 0, java.math.RoundingMode.DOWN).intValue();
        if (points <= 0) {
            return;
        }

        Membership membership = membershipRepository.findByUserId(userId).orElse(null);
        if (membership == null) {
            log.warn("用户[{}]无会员记录，跳过积分发放", userId);
            return;
        }

        int balanceBefore = membership.getPoints() != null ? membership.getPoints() : 0;
        int balanceAfter = balanceBefore + points;

        PointsLog pointsLog = PointsLog.builder()
                .userId(userId)
                .membershipId(membership.getId())
                .changeType("EARN")
                .changeAmount(points)
                .balanceBefore(balanceBefore)
                .balanceAfter(balanceAfter)
                .sourceType("ORDER")
                .sourceId(orderId)
                .description("订单支付获得积分")
                .build();
        pointsLogRepository.save(pointsLog);

        // 更新会员积分和等级
        membership.setPoints(balanceAfter);
        membership.setTotalPoints((membership.getTotalPoints() != null ? membership.getTotalPoints() : 0) + points);
        autoUpgradeLevel(membership);
        membershipRepository.save(membership);

        log.info("用户[{}]订单[{}]获得{}积分，余额:{}", userId, orderId, points, balanceAfter);
    }

    @Override
    @Transactional
    public void deductPointsForRefund(Long userId, Long orderId, BigDecimal refundAmount) {
        int points = refundAmount.divide(POINTS_RATIO, 0, java.math.RoundingMode.DOWN).intValue();
        if (points <= 0) {
            return;
        }

        Membership membership = membershipRepository.findByUserId(userId).orElse(null);
        if (membership == null) {
            return;
        }

        int balanceBefore = membership.getPoints() != null ? membership.getPoints() : 0;
        int deduct = Math.min(points, balanceBefore);
        if (deduct <= 0) {
            return;
        }
        int balanceAfter = balanceBefore - deduct;

        PointsLog pointsLog = PointsLog.builder()
                .userId(userId)
                .membershipId(membership.getId())
                .changeType("SPEND")
                .changeAmount(-deduct)
                .balanceBefore(balanceBefore)
                .balanceAfter(balanceAfter)
                .sourceType("REFUND")
                .sourceId(orderId)
                .description("退款扣减积分")
                .build();
        pointsLogRepository.save(pointsLog);

        membership.setPoints(balanceAfter);
        membershipRepository.save(membership);

        log.info("用户[{}]订单[{}]退款扣减{}积分，余额:{}", userId, orderId, deduct, balanceAfter);
    }

    @Override
    public Page<PointsLogResponse> getPointsHistory(Long userId, Pageable pageable) {
        return pointsLogRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(this::toResponse);
    }

    private void autoUpgradeLevel(Membership m) {
        int total = m.getTotalPoints() != null ? m.getTotalPoints() : 0;
        if (total >= 5000) {
            m.setLevel("DIAMOND");
        } else if (total >= 1000) {
            m.setLevel("VIP");
        }
    }

    private PointsLogResponse toResponse(PointsLog log) {
        return PointsLogResponse.builder()
                .id(log.getId())
                .userId(log.getUserId())
                .changeType(log.getChangeType())
                .changeAmount(log.getChangeAmount())
                .balanceBefore(log.getBalanceBefore())
                .balanceAfter(log.getBalanceAfter())
                .sourceType(log.getSourceType())
                .sourceId(log.getSourceId())
                .description(log.getDescription())
                .createdAt(log.getCreatedAt())
                .build();
    }
}
