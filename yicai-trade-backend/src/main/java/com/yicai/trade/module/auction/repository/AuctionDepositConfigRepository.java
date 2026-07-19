package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionDepositConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AuctionDepositConfigRepository extends JpaRepository<AuctionDepositConfig, Long> {
    Optional<AuctionDepositConfig> findByConfigKey(String configKey);
}
