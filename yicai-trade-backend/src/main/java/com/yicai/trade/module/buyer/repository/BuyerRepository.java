package com.yicai.trade.module.buyer.repository;

import com.yicai.trade.module.buyer.entity.Buyer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BuyerRepository extends JpaRepository<Buyer, Long> {
    Optional<Buyer> findByUserId(Long userId);

    @Query("SELECT b FROM Buyer b WHERE " +
           "(:keyword IS NULL OR b.companyName LIKE %:keyword% OR b.contactPerson LIKE %:keyword%)")
    Page<Buyer> search(@Param("keyword") String keyword, Pageable pageable);
}
