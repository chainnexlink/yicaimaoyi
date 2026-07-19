package com.yicai.trade.module.dispute.repository;

import com.yicai.trade.module.dispute.entity.DisputeMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DisputeMessageRepository extends JpaRepository<DisputeMessage, Long> {
    List<DisputeMessage> findByDisputeIdOrderByCreatedAtAsc(Long disputeId);
}
