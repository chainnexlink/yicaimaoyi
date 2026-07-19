package com.yicai.trade.module.contract.repository;

import com.yicai.trade.module.contract.entity.Contract;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ContractRepository extends JpaRepository<Contract, Long> {
    
    Optional<Contract> findByContractNo(String contractNo);
    
    Optional<Contract> findByQuotationId(Long quotationId);
    
    Page<Contract> findByBuyerId(Long buyerId, Pageable pageable);
    
    Page<Contract> findByBuyerIdAndStatus(Long buyerId, String status, Pageable pageable);
    
    Page<Contract> findBySupplierId(Long supplierId, Pageable pageable);
    
    Page<Contract> findBySupplierIdAndStatus(Long supplierId, String status, Pageable pageable);
    
    Page<Contract> findByStatus(String status, Pageable pageable);
    
    Long countByStatus(String status);
    
    // 按采购模式查询
    Page<Contract> findByProcurementMode(String procurementMode, Pageable pageable);
    
    Page<Contract> findByBuyerIdAndProcurementMode(Long buyerId, String procurementMode, Pageable pageable);
    
    Page<Contract> findByProcurementModeAndStatus(String procurementMode, String status, Pageable pageable);
    
    Long countByProcurementMode(String procurementMode);
    
    // 按智能匹配会话查询
    Optional<Contract> findBySmartMatchSessionId(String sessionId);
    
    // ===== 待签合同查询 =====
    
    // 采购商待签合同（买方未签署）
    @Query("SELECT c FROM Contract c WHERE c.buyerId = :buyerId AND c.buyerSigned = false ORDER BY c.createdAt DESC")
    List<Contract> findPendingSignByBuyerId(@Param("buyerId") Long buyerId);
    
    // 供应商待签合同（卖方未签署，且买方已签署）
    @Query("SELECT c FROM Contract c WHERE c.supplierId = :supplierId AND c.supplierSigned = false AND c.buyerSigned = true ORDER BY c.createdAt DESC")
    List<Contract> findPendingSignBySupplierId(@Param("supplierId") Long supplierId);
    
    // 平台代采待签合同（平台需要协调签署）
    @Query("SELECT c FROM Contract c WHERE c.procurementMode = 'PLATFORM_PROCUREMENT' AND (c.buyerSigned = false OR c.supplierSigned = false) ORDER BY c.createdAt DESC")
    List<Contract> findPlatformPendingContracts();
    
    // 所有待签合同
    @Query("SELECT c FROM Contract c WHERE c.buyerSigned = false OR c.supplierSigned = false ORDER BY c.createdAt DESC")
    List<Contract> findAllPendingContracts();
    
    // 统计待签合同数量
    @Query("SELECT COUNT(c) FROM Contract c WHERE c.buyerId = :buyerId AND c.buyerSigned = false")
    Long countPendingSignByBuyerId(@Param("buyerId") Long buyerId);
    
    @Query("SELECT COUNT(c) FROM Contract c WHERE c.supplierId = :supplierId AND c.supplierSigned = false AND c.buyerSigned = true")
    Long countPendingSignBySupplierId(@Param("supplierId") Long supplierId);

    // ===== 管理后台多维筛选 =====

    @Query("SELECT c FROM Contract c WHERE " +
            "(:status IS NULL OR c.status = :status) AND " +
            "(:contractType IS NULL OR c.contractType = :contractType) AND " +
            "(:procurementMode IS NULL OR c.procurementMode = :procurementMode) AND " +
            "(:keyword IS NULL OR c.contractTitle LIKE CONCAT('%',:keyword,'%') OR c.contractNo LIKE CONCAT('%',:keyword,'%'))")
    Page<Contract> findByAdminFilters(
            @Param("status") String status,
            @Param("contractType") String contractType,
            @Param("procurementMode") String procurementMode,
            @Param("keyword") String keyword,
            Pageable pageable);

    @Query("SELECT c.status, COUNT(c) FROM Contract c GROUP BY c.status")
    List<Object[]> countGroupByStatus();

    @Query("SELECT c.contractType, COUNT(c) FROM Contract c GROUP BY c.contractType")
    List<Object[]> countGroupByType();

    @Query("SELECT c.procurementMode, COUNT(c) FROM Contract c GROUP BY c.procurementMode")
    List<Object[]> countGroupByMode();

    // 定时任务: 查找已过期但仍在执行中的合同
    @Query("SELECT c FROM Contract c WHERE c.status = 'EXECUTING' AND c.endDate IS NOT NULL AND c.endDate < :now")
    List<Contract> findExpiredExecutingContracts(@Param("now") LocalDate now);

    // 按合同审核状态查询（纸质合同审核）
    List<Contract> findByContractReviewStatus(String contractReviewStatus);
}
