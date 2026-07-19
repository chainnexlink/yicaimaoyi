package com.yicai.trade.module.supplier.repository;

import com.yicai.trade.module.supplier.entity.SupplierProduct;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface SupplierProductRepository extends JpaRepository<SupplierProduct, Long> {

    Page<SupplierProduct> findBySupplierId(Long supplierId, Pageable pageable);

    @Query("SELECT p FROM SupplierProduct p WHERE p.supplierId = :supplierId " +
           "AND (:keyword IS NULL OR p.productName LIKE %:keyword% OR p.category LIKE %:keyword%)")
    Page<SupplierProduct> search(@Param("supplierId") Long supplierId,
                                 @Param("keyword") String keyword,
                                 Pageable pageable);
}
