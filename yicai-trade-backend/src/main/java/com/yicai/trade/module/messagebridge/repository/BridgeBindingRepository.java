package com.yicai.trade.module.messagebridge.repository;

import com.yicai.trade.module.messagebridge.entity.MessageBridgeBinding;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BridgeBindingRepository extends JpaRepository<MessageBridgeBinding, Long> {

    Optional<MessageBridgeBinding> findBySupplierIdAndChannelType(Long supplierId, String channelType);

    List<MessageBridgeBinding> findBySupplierId(Long supplierId);

    Optional<MessageBridgeBinding> findByChannelTypeAndChannelUserId(String channelType, String channelUserId);

    Page<MessageBridgeBinding> findByBindStatus(String bindStatus, Pageable pageable);

    long countByBindStatus(String bindStatus);
}
