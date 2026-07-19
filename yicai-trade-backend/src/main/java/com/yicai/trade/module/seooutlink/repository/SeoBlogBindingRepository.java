package com.yicai.trade.module.seooutlink.repository;

import com.yicai.trade.module.seooutlink.entity.SeoBlogBinding;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SeoBlogBindingRepository extends JpaRepository<SeoBlogBinding, Long> {

    List<SeoBlogBinding> findBySupplierId(Long supplierId);

    Optional<SeoBlogBinding> findBySupplierIdAndPlatform(Long supplierId, String platform);

    List<SeoBlogBinding> findByAutoPublishTrueAndStatus(String status);

    long countBySupplierId(Long supplierId);
}
