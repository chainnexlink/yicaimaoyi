package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionSupplierList;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionSupplierListRepository extends JpaRepository<AuctionSupplierList, Long> {

    List<AuctionSupplierList> findByBuyerIdAndListType(Long buyerId, String listType);

    Optional<AuctionSupplierList> findByBuyerIdAndSupplierIdAndListType(Long buyerId, Long supplierId, String listType);

    boolean existsByBuyerIdAndSupplierIdAndListType(Long buyerId, Long supplierId, String listType);

    void deleteByBuyerIdAndSupplierIdAndListType(Long buyerId, Long supplierId, String listType);

    List<AuctionSupplierList> findByBuyerIdOrderByCreatedAtDesc(Long buyerId);

    int countByBuyerIdAndListType(Long buyerId, String listType);
}
