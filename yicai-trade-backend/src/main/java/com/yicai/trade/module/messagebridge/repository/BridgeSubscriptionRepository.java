package com.yicai.trade.module.messagebridge.repository;

import com.yicai.trade.module.messagebridge.entity.MessageBridgeSubscription;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface BridgeSubscriptionRepository extends JpaRepository<MessageBridgeSubscription, Long> {

    Optional<MessageBridgeSubscription> findBySubscriptionNo(String subscriptionNo);

    List<MessageBridgeSubscription> findBySupplierIdAndStatus(Long supplierId, String status);

    Page<MessageBridgeSubscription> findBySupplierId(Long supplierId, Pageable pageable);

    Page<MessageBridgeSubscription> findByStatus(String status, Pageable pageable);

    @Query("SELECT s FROM MessageBridgeSubscription s WHERE s.supplierId = :supplierId AND s.status = 'ACTIVE' " +
            "AND (s.channelType = :channelType OR s.channelType = 'ALL') AND s.endDate >= :today")
    List<MessageBridgeSubscription> findActiveSubscription(
            @Param("supplierId") Long supplierId,
            @Param("channelType") String channelType,
            @Param("today") LocalDate today);

    List<MessageBridgeSubscription> findByStatusAndEndDateBefore(String status, LocalDate date);

    List<MessageBridgeSubscription> findByStatusAndEndDateBetween(String status, LocalDate from, LocalDate to);

    List<MessageBridgeSubscription> findByStatusAndAutoRenewTrueAndEndDate(String status, LocalDate date);

    long countByStatus(String status);

    @Query("SELECT COALESCE(SUM(s.amount), 0) FROM MessageBridgeSubscription s WHERE s.status IN ('ACTIVE', 'EXPIRED')")
    java.math.BigDecimal sumTotalRevenue();
}
