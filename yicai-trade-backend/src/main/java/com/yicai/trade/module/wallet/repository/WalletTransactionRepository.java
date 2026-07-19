package com.yicai.trade.module.wallet.repository;

import com.yicai.trade.module.wallet.entity.WalletTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, Long> {

    Page<WalletTransaction> findByWalletId(Long walletId, Pageable pageable);

    Page<WalletTransaction> findByOwnerIdAndOwnerType(Long ownerId, String ownerType, Pageable pageable);

    List<WalletTransaction> findByContractId(Long contractId);

    List<WalletTransaction> findByCommissionId(Long commissionId);

    Page<WalletTransaction> findByOwnerType(String ownerType, Pageable pageable);

    Page<WalletTransaction> findByTransactionType(String transactionType, Pageable pageable);

    Page<WalletTransaction> findByOwnerTypeAndTransactionType(String ownerType, String transactionType, Pageable pageable);
}
