package com.yicai.trade.module.wallet.repository;

import com.yicai.trade.module.wallet.entity.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface WalletRepository extends JpaRepository<Wallet, Long> {

    Optional<Wallet> findByOwnerIdAndOwnerType(Long ownerId, String ownerType);

    List<Wallet> findByOwnerType(String ownerType);

    boolean existsByOwnerIdAndOwnerType(Long ownerId, String ownerType);
}
