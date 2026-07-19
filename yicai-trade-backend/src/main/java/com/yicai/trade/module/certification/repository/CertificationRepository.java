package com.yicai.trade.module.certification.repository;

import com.yicai.trade.module.certification.entity.Certification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CertificationRepository extends JpaRepository<Certification, Long> {
    Page<Certification> findByStatus(String status, Pageable pageable);
    Page<Certification> findByCertType(String certType, Pageable pageable);
    List<Certification> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<Certification> findByUserIdAndStatus(Long userId, String status);
    long countByStatus(String status);
}
