package com.yicai.trade.module.contract.repository;

import com.yicai.trade.module.contract.entity.ContractChangeLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContractChangeLogRepository extends JpaRepository<ContractChangeLog, Long> {
    
    List<ContractChangeLog> findByContractId(Long contractId);
    
    List<ContractChangeLog> findByContractIdAndStatus(Long contractId, String status);
}
