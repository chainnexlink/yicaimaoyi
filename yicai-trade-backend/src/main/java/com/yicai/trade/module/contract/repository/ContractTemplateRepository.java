package com.yicai.trade.module.contract.repository;

import com.yicai.trade.module.contract.entity.ContractTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ContractTemplateRepository extends JpaRepository<ContractTemplate, Long> {
    
    Optional<ContractTemplate> findByTemplateCode(String templateCode);
    
    List<ContractTemplate> findByIsActiveTrue();
    
    List<ContractTemplate> findByIsActiveTrueAndCategory(String category);
    
    Optional<ContractTemplate> findByIsDefaultTrue();

    List<ContractTemplate> findBySubmitterTypeAndSubmitterId(String submitterType, Long submitterId);

    List<ContractTemplate> findByAuditStatus(String auditStatus);

    List<ContractTemplate> findByAuditStatusOrderByCreatedAtDesc(String auditStatus);

    List<ContractTemplate> findBySubmitterTypeAndSubmitterIdAndAuditStatus(String submitterType, Long submitterId, String auditStatus);
}
