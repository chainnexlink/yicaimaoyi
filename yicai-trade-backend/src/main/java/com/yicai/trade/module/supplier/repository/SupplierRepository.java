package com.yicai.trade.module.supplier.repository;

import com.yicai.trade.module.supplier.entity.Supplier;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SupplierRepository extends JpaRepository<Supplier, Long> {
    
    long countByStatus(String status);
    
    Optional<Supplier> findByUserId(Long userId);
    
    @Query("SELECT s FROM Supplier s WHERE " +
           "(:keyword IS NULL OR s.companyName LIKE %:keyword% OR s.description LIKE %:keyword%) " +
           "AND (:status IS NULL OR s.status = :status)")
    Page<Supplier> search(@Param("keyword") String keyword,
                         @Param("status") String status,
                         Pageable pageable);
}
