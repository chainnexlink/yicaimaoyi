package com.yicai.trade.module.messagebridge.repository;

import com.yicai.trade.module.messagebridge.entity.MessageBridgeConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BridgeConfigRepository extends JpaRepository<MessageBridgeConfig, Long> {

    Optional<MessageBridgeConfig> findByConfigKey(String configKey);

    List<MessageBridgeConfig> findAllByOrderByIdAsc();
}
