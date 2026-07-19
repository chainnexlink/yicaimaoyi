package com.yicai.trade.module.buyer.repository;

import com.yicai.trade.module.buyer.entity.BuyerFavorite;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BuyerFavoriteRepository extends JpaRepository<BuyerFavorite, Long> {
    
    boolean existsByBuyerIdAndProductId(Long buyerId, Long productId);
    
    void deleteByBuyerIdAndProductId(Long buyerId, Long productId);
    
    Page<BuyerFavorite> findByBuyerId(Long buyerId, Pageable pageable);
}
