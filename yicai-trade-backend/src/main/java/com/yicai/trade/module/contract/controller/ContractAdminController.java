package com.yicai.trade.module.contract.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.contract.dto.ContractResponse;
import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.entity.ContractChangeLog;
import com.yicai.trade.module.contract.repository.ContractChangeLogRepository;
import com.yicai.trade.module.contract.repository.ContractRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/contracts")
@RequiredArgsConstructor
@Tag(name = "ContractAdmin", description = "合同管理后台")
public class ContractAdminController {

    private final ContractRepository contractRepository;
    private final ContractChangeLogRepository changeLogRepository;

    // ===== L2: 合同列表(多维筛选) =====

    @GetMapping
    @Operation(summary = "管理端-合同分页列表(多维筛选)")
    public Result<PageResult<ContractResponse>> listContracts(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size,
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "contractType", required = false) String contractType,
            @RequestParam(name = "procurementMode", required = false) String procurementMode,
            @RequestParam(name = "keyword", required = false) String keyword,
            @RequestParam(name = "sortBy", defaultValue = "createdAt") String sortBy,
            @RequestParam(name = "sortDir", defaultValue = "desc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        PageRequest pageable = PageRequest.of(page, size, sort);

        if (status != null && status.isBlank()) status = null;
        if (contractType != null && contractType.isBlank()) contractType = null;
        if (procurementMode != null && procurementMode.isBlank()) procurementMode = null;
        if (keyword != null && keyword.isBlank()) keyword = null;

        Page<Contract> pageData = contractRepository.findByAdminFilters(status, contractType, procurementMode, keyword, pageable);

        List<ContractResponse> list = pageData.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return Result.success(PageResult.of(list, pageData.getTotalElements(), page, size));
    }

    // ===== L2: 统计汇总 =====

    @GetMapping("/stats")
    @Operation(summary = "合同统计汇总")
    public Result<Map<String, Object>> getStats() {
        Map<String, Object> stats = new LinkedHashMap<>();

        long total = contractRepository.count();
        stats.put("total", total);

        // 状态分布
        Map<String, Long> statusMap = new LinkedHashMap<>();
        contractRepository.countGroupByStatus().forEach(row -> {
                String key = row[0] != null ? (String) row[0] : "UNKNOWN";
                statusMap.put(key, (Long) row[1]);
        });
        stats.put("statusCounts", statusMap);
        stats.put("draft", statusMap.getOrDefault("DRAFT", 0L));
        stats.put("pendingBuyer", statusMap.getOrDefault("PENDING_BUYER", 0L));
        stats.put("pendingSupplier", statusMap.getOrDefault("PENDING_SUPPLIER", 0L));
        stats.put("signed", statusMap.getOrDefault("SIGNED", 0L));
        stats.put("executing", statusMap.getOrDefault("EXECUTING", 0L));
        stats.put("completed", statusMap.getOrDefault("COMPLETED", 0L));
        stats.put("terminated", statusMap.getOrDefault("TERMINATED", 0L));

        long pending = statusMap.getOrDefault("DRAFT", 0L)
                + statusMap.getOrDefault("PENDING_BUYER", 0L)
                + statusMap.getOrDefault("PENDING_SUPPLIER", 0L);
        stats.put("pendingTotal", pending);

        // 类型分布
        Map<String, Long> typeMap = new LinkedHashMap<>();
        contractRepository.countGroupByType().forEach(row -> {
                String key = row[0] != null ? (String) row[0] : "UNKNOWN";
                typeMap.put(key, (Long) row[1]);
        });
        stats.put("typeCounts", typeMap);

        // 模式分布
        Map<String, Long> modeMap = new LinkedHashMap<>();
        contractRepository.countGroupByMode().forEach(row -> {
                String key = row[0] != null ? (String) row[0] : "UNKNOWN";
                modeMap.put(key, (Long) row[1]);
        });
        stats.put("modeCounts", modeMap);
        stats.put("platformCount", modeMap.getOrDefault("PLATFORM_PROCUREMENT", 0L));
        stats.put("directCount", modeMap.getOrDefault("DIRECT_PROCUREMENT", 0L));

        return Result.success(stats);
    }

    // ===== L3: 合同详情 =====

    @GetMapping("/{id}")
    @Operation(summary = "合同详情(含变更记录)")
    public Result<Map<String, Object>> getContractDetail(@PathVariable("id") Long id) {
        Contract contract = contractRepository.findById(id).orElse(null);
        if (contract == null) return Result.notFound("合同不存在");

        Map<String, Object> detail = new LinkedHashMap<>();
        detail.put("contract", toResponse(contract));

        // 变更记录
        List<ContractChangeLog> changeLogs = changeLogRepository.findByContractId(id);
        detail.put("changeLogs", changeLogs);
        detail.put("changeLogCount", changeLogs.size());
        long pendingChanges = changeLogs.stream().filter(cl -> "PENDING".equals(cl.getStatus())).count();
        detail.put("pendingChanges", pendingChanges);

        // 签署进度
        Map<String, Object> signProgress = new LinkedHashMap<>();
        signProgress.put("buyerSigned", Boolean.TRUE.equals(contract.getBuyerSigned()));
        signProgress.put("buyerSignedAt", contract.getBuyerSignedAt());
        signProgress.put("supplierSigned", Boolean.TRUE.equals(contract.getSupplierSigned()));
        signProgress.put("supplierSignedAt", contract.getSupplierSignedAt());
        signProgress.put("platformReviewed", Boolean.TRUE.equals(contract.getPlatformReviewed()));
        signProgress.put("platformReviewedAt", contract.getPlatformReviewedAt());
        signProgress.put("platformReviewNote", contract.getPlatformReviewNote());
        detail.put("signProgress", signProgress);

        // 金额摘要
        Map<String, Object> financeSummary = new LinkedHashMap<>();
        financeSummary.put("totalAmount", contract.getTotalAmount());
        financeSummary.put("currency", contract.getCurrency());
        detail.put("financeSummary", financeSummary);

        return Result.success(detail);
    }

    // ===== L3: 合同变更记录 =====

    @GetMapping("/{id}/changes")
    @Operation(summary = "合同变更记录列表")
    public Result<List<ContractChangeLog>> getContractChanges(@PathVariable("id") Long id) {
        return Result.success(changeLogRepository.findByContractId(id));
    }

    // ===== L4: 单个变更记录详情 =====

    @GetMapping("/changes/{changeId}")
    @Operation(summary = "变更记录详情")
    public Result<Map<String, Object>> getChangeDetail(@PathVariable("changeId") Long changeId) {
        ContractChangeLog cl = changeLogRepository.findById(changeId).orElse(null);
        if (cl == null) return Result.notFound("变更记录不存在");

        Map<String, Object> detail = new LinkedHashMap<>();
        detail.put("changeLog", cl);

        // 关联合同
        Contract contract = contractRepository.findById(cl.getContractId()).orElse(null);
        if (contract != null) {
            detail.put("contract", toResponse(contract));
        }

        return Result.success(detail);
    }

    // ===== 管理操作 =====

    @PostMapping("/{id}/terminate")
    @Operation(summary = "管理员终止合同")
    public Result<Void> terminateContract(@PathVariable("id") Long id) {
        Contract c = contractRepository.findById(id).orElse(null);
        if (c == null) return Result.notFound("合同不存在");
        if ("TERMINATED".equals(c.getStatus()) || "COMPLETED".equals(c.getStatus())) {
            return Result.badRequest("合同已终止或已完成，无法操作");
        }
        c.setStatus("TERMINATED");
        contractRepository.save(c);
        return Result.success();
    }

    @PostMapping("/{id}/review")
    @Operation(summary = "平台审核合同")
    public Result<Void> reviewContract(
            @PathVariable("id") Long id,
            @RequestParam(name = "note", defaultValue = "") String note) {
        Contract c = contractRepository.findById(id).orElse(null);
        if (c == null) return Result.notFound("合同不存在");
        c.setPlatformReviewed(true);
        c.setPlatformReviewedAt(java.time.LocalDateTime.now());
        c.setPlatformReviewNote(note);
        contractRepository.save(c);
        return Result.success();
    }

    @PostMapping("/changes/{changeId}/approve")
    @Operation(summary = "审批变更申请")
    public Result<Void> approveChange(
            @PathVariable("changeId") Long changeId,
            @RequestParam(name = "action") String action,
            @RequestParam(name = "note", defaultValue = "") String note) {
        ContractChangeLog cl = changeLogRepository.findById(changeId).orElse(null);
        if (cl == null) return Result.notFound("变更记录不存在");
        if (!"PENDING".equals(cl.getStatus())) return Result.badRequest("变更已处理");

        if ("approve".equalsIgnoreCase(action)) {
            cl.setStatus("APPROVED");
        } else {
            cl.setStatus("REJECTED");
        }
        cl.setApprovalNote(note);
        cl.setApprovedAt(java.time.LocalDateTime.now());
        changeLogRepository.save(cl);
        return Result.success();
    }

    // ===== 工具方法 =====

    private ContractResponse toResponse(Contract c) {
        String modeDisplay = "PLATFORM_PROCUREMENT".equals(c.getProcurementMode()) ? "平台代采" : "直接采购";
        List<ContractChangeLog> logs = changeLogRepository.findByContractId(c.getId());
        List<ContractResponse.ChangeLogResponse> logResps = logs.stream().map(cl ->
                ContractResponse.ChangeLogResponse.builder()
                        .id(cl.getId())
                        .changeType(cl.getChangeType())
                        .changeReason(cl.getChangeReason())
                        .initiatorType(cl.getInitiatorType())
                        .initiatorId(cl.getInitiatorId())
                        .initiatorName(cl.getInitiatorName())
                        .status(cl.getStatus())
                        .approvalNote(cl.getApprovalNote())
                        .approvedAt(cl.getApprovedAt())
                        .createdAt(cl.getCreatedAt())
                        .build()
        ).collect(Collectors.toList());

        return ContractResponse.builder()
                .id(c.getId())
                .contractNo(c.getContractNo())
                .inquiryId(c.getInquiryId())
                .quotationId(c.getQuotationId())
                .auctionId(c.getAuctionId())
                .buyerId(c.getBuyerId())
                .supplierId(c.getSupplierId())
                .contractType(c.getContractType())
                .contractTitle(c.getContractTitle())
                .totalAmount(c.getTotalAmount())
                .currency(c.getCurrency())
                .procurementMode(c.getProcurementMode())
                .procurementModeDisplay(modeDisplay)
                .recommendedSuppliers(c.getRecommendedSuppliers())
                .smartMatchSessionId(c.getSmartMatchSessionId())
                .smartMatchProductName(c.getSmartMatchProductName())
                .smartMatchCategoryCode(c.getSmartMatchCategoryCode())
                .contractContent(c.getContractContent())
                .templateId(c.getTemplateId())
                .status(c.getStatus())
                .buyerSigned(c.getBuyerSigned())
                .buyerSignedAt(c.getBuyerSignedAt())
                .supplierSigned(c.getSupplierSigned())
                .supplierSignedAt(c.getSupplierSignedAt())
                .startDate(c.getStartDate())
                .endDate(c.getEndDate())
                .deliveryDate(c.getDeliveryDate())
                .paymentTerms(c.getPaymentTerms())
                .qualityStandards(c.getQualityStandards())
                .contractPdfUrl(c.getContractPdfUrl())
                .orderId(c.getOrderId())
                .platformReviewed(c.getPlatformReviewed())
                .platformReviewerId(c.getPlatformReviewerId())
                .platformReviewedAt(c.getPlatformReviewedAt())
                .platformReviewNote(c.getPlatformReviewNote())
                .remark(c.getRemark())
                .changeLogs(logResps)
                .createdAt(c.getCreatedAt())
                .updatedAt(c.getUpdatedAt())
                .build();
    }
}
