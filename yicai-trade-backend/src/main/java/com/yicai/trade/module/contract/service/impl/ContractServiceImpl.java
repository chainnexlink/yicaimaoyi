package com.yicai.trade.module.contract.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.contract.dto.*;
import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.entity.ContractChangeLog;
import com.yicai.trade.module.contract.entity.ContractTemplate;
import com.yicai.trade.module.contract.repository.ContractChangeLogRepository;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.contract.repository.ContractTemplateRepository;
import com.yicai.trade.module.contract.service.ContractPdfService;
import com.yicai.trade.module.contract.service.ContractService;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.wallet.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ContractServiceImpl implements ContractService {

    private final ContractRepository contractRepository;
    private final ContractChangeLogRepository changeLogRepository;
    private final ContractTemplateRepository templateRepository;
    private final OrderRepository orderRepository;
    private final WalletService walletService;
    private final ContractPdfService contractPdfService;

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse createContract(Long buyerId, ContractCreateRequest request) {
        // 如果基于报价单创建，检查是否已存在合同
        if (request.getQuotationId() != null) {
            contractRepository.findByQuotationId(request.getQuotationId()).ifPresent(c -> {
                throw new BusinessException(ErrorCode.CONTRACT_DUPLICATE);
            });
        }
        
        // 确定采购模式，默认为直接采购
        String procurementMode = request.getProcurementMode() != null 
                ? request.getProcurementMode() 
                : "DIRECT_PROCUREMENT";
        
        // 平台代采时，supplierId 可以为空或设为平台ID(0)
        Long supplierId = request.getSupplierId();
        if ("PLATFORM_PROCUREMENT".equals(procurementMode) && supplierId == null) {
            supplierId = 0L;  // 平台代采时使用0表示平台
        }

        // 如果前端传了 templateCode 但没传 templateId，尝试通过 code 查找
        Long templateId = request.getTemplateId();
        if (templateId == null && request.getTemplateCode() != null && !request.getTemplateCode().isBlank()) {
            templateRepository.findByTemplateCode(request.getTemplateCode())
                    .ifPresent(t -> request.setTemplateId(t.getId()));
            templateId = request.getTemplateId();
        }

        // 将前端传入的附加字段拼入 remark（这些字段不在数据库合同表中，但需要保留）
        StringBuilder remarkBuilder = new StringBuilder(request.getRemark() != null ? request.getRemark() : "");
        if (request.getQuantity() != null) {
            remarkBuilder.append("\n[采购数量] ").append(request.getQuantity())
                    .append(" ").append(request.getUnit() != null ? request.getUnit() : "件");
        }
        if (request.getDeliveryAddress() != null && !request.getDeliveryAddress().isBlank()) {
            remarkBuilder.append("\n[交货地址] ").append(request.getDeliveryAddress());
        }
        if (request.getServiceRate() != null && !request.getServiceRate().isBlank()) {
            remarkBuilder.append("\n[服务费率] ").append(request.getServiceRate());
        }
        String finalRemark = remarkBuilder.toString().trim();

        @lombok.NonNull Contract contract = Contract.builder()
                .contractNo(generateContractNo())
                .inquiryId(request.getInquiryId())
                .quotationId(request.getQuotationId())
                .auctionId(request.getAuctionId())
                .buyerId(buyerId)
                .supplierId(supplierId)
                .contractType(request.getContractType() != null ? request.getContractType() : "PURCHASE")
                .procurementMode(procurementMode)
                .recommendedSuppliers(request.getRecommendedSuppliers())
                .smartMatchSessionId(request.getSmartMatchSessionId())
                .smartMatchProductName(request.getSmartMatchProductName())
                .smartMatchCategoryCode(request.getSmartMatchCategoryCode())
                .contractTitle(request.getContractTitle())
                .totalAmount(request.getTotalAmount())
                .currency(request.getCurrency() != null ? request.getCurrency() : "CNY")
                .contractContent(request.getContractContent())
                .templateId(templateId)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .deliveryDate(request.getDeliveryDate())
                .paymentTerms(request.getPaymentTerms())
                .qualityStandards(request.getQualityStandards())
                .remark(finalRemark.isEmpty() ? null : finalRemark)
                .status("DRAFT")
                .build();

        return toResponse(contractRepository.save(contract), null);
    }

    @Override
    @SuppressWarnings("null")
    public ContractResponse getContract(@lombok.NonNull Long contractId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));
        List<ContractChangeLog> logs = changeLogRepository.findByContractId(contractId);
        return toResponse(contract, logs);
    }

    @Override
    public ContractResponse getContractByNo(String contractNo) {
        Contract contract = contractRepository.findByContractNo(contractNo)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));
        List<ContractChangeLog> logs = changeLogRepository.findByContractId(contract.getId());
        return toResponse(contract, logs);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse buyerSign(@lombok.NonNull Long contractId, Long buyerId, ContractSignRequest request) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        if (!contract.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (Boolean.TRUE.equals(contract.getBuyerSigned())) {
            throw new BusinessException(ErrorCode.CONTRACT_ALREADY_SIGNED);
        }

        // 一键签署：自动填充签名
        String signature = (request.getSignature() != null && !request.getSignature().isBlank())
                ? request.getSignature() : "Buyer#" + buyerId;

        contract.setBuyerSigned(true);
        contract.setBuyerSignedAt(LocalDateTime.now());
        contract.setBuyerSignature(signature);

        // 双方都已签署 → 生成PDF、创建订单（待纸质合同审核）
        if (Boolean.TRUE.equals(contract.getSupplierSigned())) {
            contract.setStatus("SIGNED");
            contract.setContractReviewStatus("PENDING_UPLOAD");
            Contract saved = contractRepository.save(contract);
            generatePdfAndOrder(saved);
            return toResponse(contractRepository.findById(saved.getId()).orElse(saved), null);
        } else {
            contract.setStatus("PENDING_SUPPLIER");
        }

        return toResponse(contractRepository.save(contract), null);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse supplierSign(@lombok.NonNull Long contractId, Long supplierId, ContractSignRequest request) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        if (!contract.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (Boolean.TRUE.equals(contract.getSupplierSigned())) {
            throw new BusinessException(ErrorCode.CONTRACT_ALREADY_SIGNED);
        }

        // 一键签署：自动填充签名
        String signature = (request.getSignature() != null && !request.getSignature().isBlank())
                ? request.getSignature() : "Supplier#" + supplierId;

        contract.setSupplierSigned(true);
        contract.setSupplierSignedAt(LocalDateTime.now());
        contract.setSupplierSignature(signature);

        // 双方都已签署 → 生成PDF、创建订单（待纸质合同审核）
        if (Boolean.TRUE.equals(contract.getBuyerSigned())) {
            contract.setStatus("SIGNED");
            contract.setContractReviewStatus("PENDING_UPLOAD");
            Contract saved = contractRepository.save(contract);
            generatePdfAndOrder(saved);
            return toResponse(contractRepository.findById(saved.getId()).orElse(saved), null);
        } else {
            contract.setStatus("PENDING_BUYER");
        }

        return toResponse(contractRepository.save(contract), null);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public Long generateOrderFromContract(@lombok.NonNull Long contractId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        if (!"SIGNED".equals(contract.getStatus())) {
            throw new BusinessException(ErrorCode.CONTRACT_NOT_SIGNED);
        }
        // 如果已经关联了订单，直接返回
        if (contract.getOrderId() != null) {
            return contract.getOrderId();
        }

        // 生成订单 — 状态为 PENDING_CONTRACT_REVIEW（等待纸质合同审核通过后才触发执行）
        String orderNo = "OD" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);

        @lombok.NonNull Order order = Order.builder()
                .orderNo(orderNo)
                .buyerId(contract.getBuyerId())
                .supplierId(contract.getSupplierId())
                .totalAmount(contract.getTotalAmount())
                .status("PENDING_CONTRACT_REVIEW")
                .paymentStatus("UNPAID")
                .contractUrl(contract.getContractPdfUrl())
                .remark("由合同 " + contract.getContractNo() + " 自动生成，等待纸质合同审核")
                .build();

        if (contract.getDeliveryDate() != null) {
            order.setRequiredDeliveryDate(contract.getDeliveryDate());
        }

        Order savedOrder = orderRepository.save(order);

        // 回写合同关联订单ID（合同保持SIGNED状态，不进入EXECUTING）
        contract.setOrderId(savedOrder.getId());
        contractRepository.save(contract);

        return savedOrder.getId();
    }

    /**
     * 上传纸质合同扫描件
     */
    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse uploadPhysicalContract(@lombok.NonNull Long contractId, Long userId, String physicalContractUrl) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        // 只有合同的买方或卖方可以上传
        if (!contract.getBuyerId().equals(userId) && !contract.getSupplierId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        // 合同必须已签署
        if (!"SIGNED".equals(contract.getStatus())) {
            throw new BusinessException(ErrorCode.CONTRACT_STATUS_INVALID, "合同尚未签署完成");
        }

        contract.setPhysicalContractUrl(physicalContractUrl);
        contract.setPhysicalContractUploadedAt(LocalDateTime.now());
        contract.setContractReviewStatus("PENDING_REVIEW");

        return toResponse(contractRepository.save(contract), null);
    }

    /**
     * 平台审核纸质合同 — 审核通过后订单才触发执行
     */
    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse reviewPhysicalContract(@lombok.NonNull Long contractId, Long reviewerId,
                                                    boolean approved, String note) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        if (!"PENDING_REVIEW".equals(contract.getContractReviewStatus())) {
            throw new BusinessException(ErrorCode.CONTRACT_STATUS_INVALID, "当前合同不在待审核状态");
        }

        contract.setContractReviewedBy(reviewerId);
        contract.setContractReviewedAt(LocalDateTime.now());
        contract.setContractReviewNote(note);

        if (approved) {
            contract.setContractReviewStatus("APPROVED");
            contract.setStatus("EXECUTING");
            contractRepository.save(contract);

            // 审核通过 → 自动创建佣金、收取服务费、激活订单
            autoCreateCommission(contract);
            activateOrder(contract);

            return toResponse(contractRepository.findById(contract.getId()).orElse(contract), null);
        } else {
            contract.setContractReviewStatus("REJECTED");
            return toResponse(contractRepository.save(contract), null);
        }
    }

    /**
     * 获取待审核纸质合同列表
     */
    @Override
    public List<ContractResponse> listPendingPhysicalReview() {
        return contractRepository.findByContractReviewStatus("PENDING_REVIEW")
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    public PageResult<ContractResponse> listBuyerContracts(Long buyerId, String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Contract> p = (status != null && !status.isBlank())
                ? contractRepository.findByBuyerIdAndStatus(buyerId, status, pr)
                : contractRepository.findByBuyerId(buyerId, pr);
        return PageResult.of(
                p.getContent().stream().map(c -> toResponse(c, null)).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<ContractResponse> listSupplierContracts(Long supplierId, String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Contract> p = (status != null && !status.isBlank())
                ? contractRepository.findBySupplierIdAndStatus(supplierId, status, pr)
                : contractRepository.findBySupplierId(supplierId, pr);
        return PageResult.of(
                p.getContent().stream().map(c -> toResponse(c, null)).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse platformReview(@lombok.NonNull Long contractId, Long reviewerId, boolean approved, String note) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        contract.setPlatformReviewed(true);
        contract.setPlatformReviewerId(reviewerId);
        contract.setPlatformReviewedAt(LocalDateTime.now());
        contract.setPlatformReviewNote(note);

        if (!approved) {
            contract.setStatus("CANCELLED");
        }

        return toResponse(contractRepository.save(contract), null);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void requestChange(@lombok.NonNull Long contractId, Long initiatorId, String initiatorType,
                              ContractChangeRequest request) {
        contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        @lombok.NonNull ContractChangeLog log = ContractChangeLog.builder()
                .contractId(contractId)
                .changeType(request.getChangeType())
                .changeReason(request.getChangeReason())
                .initiatorType(initiatorType)
                .initiatorId(initiatorId)
                .newContent(request.getNewContent())
                .status("PENDING")
                .build();
        changeLogRepository.save(log);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void approveChange(@lombok.NonNull Long changeLogId, Long approverId, String approverName,
                              boolean approved, String note) {
        ContractChangeLog log = changeLogRepository.findById(changeLogId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        log.setStatus(approved ? "APPROVED" : "REJECTED");
        log.setApproverId(approverId);
        log.setApproverName(approverName);
        log.setApprovedAt(LocalDateTime.now());
        log.setApprovalNote(note);
        changeLogRepository.save(log);

        // 如果是终止类型的变更且被批准，更新合同状态
        if (approved && "TERMINATION".equals(log.getChangeType())) {
            Contract contract = contractRepository.findById(log.getContractId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));
            contract.setStatus("TERMINATED");
            contractRepository.save(contract);
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse terminateContract(@lombok.NonNull Long contractId, Long operatorId, String reason) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        String oldStatus = contract.getStatus();
        if ("COMPLETED".equals(oldStatus) || "TERMINATED".equals(oldStatus) || "CANCELLED".equals(oldStatus)) {
            throw new BusinessException(ErrorCode.CONTRACT_STATUS_INVALID);
        }

        contract.setStatus("TERMINATED");
        contractRepository.save(contract);

        // 记录变更日志
        @lombok.NonNull ContractChangeLog log = ContractChangeLog.builder()
                .contractId(contractId)
                .changeType("TERMINATION")
                .changeReason(reason)
                .initiatorType("PLATFORM")
                .initiatorId(operatorId)
                .status("APPROVED")
                .approverId(operatorId)
                .approvedAt(LocalDateTime.now())
                .build();
        changeLogRepository.save(log);

        return toResponse(contract, changeLogRepository.findByContractId(contractId));
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ContractResponse completeContract(@lombok.NonNull Long contractId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        if (!"EXECUTING".equals(contract.getStatus())) {
            throw new BusinessException(ErrorCode.CONTRACT_STATUS_INVALID);
        }
        contract.setStatus("COMPLETED");
        Contract saved = contractRepository.save(contract);

        // 合同完成 → 触发返佣闭环：将客户自定义返佣金额入零钱
        try {
            walletService.executeRebate(contractId);
        } catch (Exception e) {
            // 返佣失败不影响合同完成，可由后台手动补偿
        }

        // 合同完成 → 供应商货款入账零钱
        try {
            walletService.recharge(
                    contract.getSupplierId(), "SUPPLIER",
                    contract.getTotalAmount(),
                    "合同 " + contract.getContractNo() + " 货款到账");
        } catch (Exception e) {
            // 入账失败不影响合同完成
        }

        return toResponse(saved, null);
    }

    @Override
    public List<ContractTemplateResponse> listActiveTemplates(String category) {
        List<ContractTemplate> templates = (category != null && !category.isBlank())
                ? templateRepository.findByIsActiveTrueAndCategory(category)
                : templateRepository.findByIsActiveTrue();
        return templates.stream().map(this::toTemplateResponse).collect(Collectors.toList());
    }

    @Override
    @SuppressWarnings("null")
    public ContractTemplateResponse getTemplate(@lombok.NonNull Long templateId) {
        ContractTemplate t = templateRepository.findById(templateId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_TEMPLATE_NOT_FOUND));
        return toTemplateResponse(t);
    }

    // ===== private helpers =====

    /** 默认返佣比例 3% */
    private static final BigDecimal DEFAULT_REBATE_RATE = new BigDecimal("0.03");

    /** 合同双方签署后，自动确保佣金记录存在（如前端未提前创建则使用默认3%返佣） */
    private void autoCreateCommission(Contract contract) {
        try {
            walletService.ensureCommission(contract.getId(), DEFAULT_REBATE_RATE);
        } catch (Exception e) {
            // 佣金创建失败不影响签署流程，可后台手动处理
        }
    }

    /** 双方签署后 → 生成PDF盖章 + 创建待审核订单 */
    private void generatePdfAndOrder(Contract contract) {
        // 1. 生成带盖章的PDF
        try {
            String pdfUrl = contractPdfService.generateSignedPdf(contract);
            if (pdfUrl != null) {
                contract.setContractPdfUrl(pdfUrl);
                contractRepository.save(contract);
            }
        } catch (Exception e) {
            log.warn("生成合同PDF失败（不影响流程）: contractId={}, error={}", contract.getId(), e.getMessage());
        }

        // 2. 自动生成订单（PENDING_CONTRACT_REVIEW状态）
        if (contract.getOrderId() == null) {
            try {
                Long orderId = generateOrderFromContract(contract.getId());
                log.info("合同签署后自动生成订单: contractId={}, orderId={}", contract.getId(), orderId);
            } catch (Exception e) {
                log.warn("自动生成订单失败（可手动操作）: contractId={}, error={}", contract.getId(), e.getMessage());
            }
        }
    }

    /** 纸质合同审核通过后 → 激活订单为PENDING状态 + 收取服务费 */
    private void activateOrder(Contract contract) {
        if (contract.getOrderId() == null) return;
        try {
            Order order = orderRepository.findById(contract.getOrderId()).orElse(null);
            if (order != null && "PENDING_CONTRACT_REVIEW".equals(order.getStatus())) {
                order.setStatus("PENDING");
                order.setRemark("纸质合同审核通过，订单已激活");
                orderRepository.save(order);
                log.info("纸质合同审核通过，订单已激活: orderId={}", order.getId());
            }
        } catch (Exception e) {
            log.warn("激活订单失败: orderId={}, error={}", contract.getOrderId(), e.getMessage());
        }
        // 收取平台服务费
        try {
            walletService.collectServiceFee(contract.getId());
        } catch (Exception e) {
            // 服务费收取失败不影响流程
        }
    }

    private String generateContractNo() {
        return "CT" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);
    }

    private ContractResponse toResponse(Contract c) {
        return toResponse(c, null);
    }

    private ContractResponse toResponse(Contract c, List<ContractChangeLog> logs) {
        List<ContractResponse.ChangeLogResponse> logResponses = (logs != null)
                ? logs.stream().map(l -> ContractResponse.ChangeLogResponse.builder()
                        .id(l.getId())
                        .changeType(l.getChangeType())
                        .changeReason(l.getChangeReason())
                        .initiatorType(l.getInitiatorType())
                        .initiatorId(l.getInitiatorId())
                        .initiatorName(l.getInitiatorName())
                        .status(l.getStatus())
                        .approvalNote(l.getApprovalNote())
                        .approvedAt(l.getApprovedAt())
                        .createdAt(l.getCreatedAt())
                        .build()).collect(Collectors.toList())
                : Collections.emptyList();
        
        // 获取采购模式显示名称
        String procurementModeDisplay = "直接采购";
        if ("PLATFORM_PROCUREMENT".equals(c.getProcurementMode())) {
            procurementModeDisplay = "平台代采";
        }

        return ContractResponse.builder()
                .id(c.getId())
                .contractNo(c.getContractNo())
                .inquiryId(c.getInquiryId())
                .quotationId(c.getQuotationId())
                .auctionId(c.getAuctionId())
                .buyerId(c.getBuyerId())
                .supplierId(c.getSupplierId())
                .contractType(c.getContractType())
                .procurementMode(c.getProcurementMode())
                .procurementModeDisplay(procurementModeDisplay)
                .recommendedSuppliers(c.getRecommendedSuppliers())
                .smartMatchSessionId(c.getSmartMatchSessionId())
                .smartMatchProductName(c.getSmartMatchProductName())
                .smartMatchCategoryCode(c.getSmartMatchCategoryCode())
                .contractTitle(c.getContractTitle())
                .totalAmount(c.getTotalAmount())
                .currency(c.getCurrency())
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
                .physicalContractUrl(c.getPhysicalContractUrl())
                .physicalContractUploadedAt(c.getPhysicalContractUploadedAt())
                .contractReviewStatus(c.getContractReviewStatus())
                .contractReviewedBy(c.getContractReviewedBy())
                .contractReviewedAt(c.getContractReviewedAt())
                .contractReviewNote(c.getContractReviewNote())
                .changeLogs(logResponses)
                .createdAt(c.getCreatedAt())
                .updatedAt(c.getUpdatedAt())
                .build();
    }

    private ContractTemplateResponse toTemplateResponse(ContractTemplate t) {
        return ContractTemplateResponse.builder()
                .id(t.getId())
                .templateName(t.getTemplateName())
                .templateCode(t.getTemplateCode())
                .templateType(t.getTemplateType())
                .templateContent(t.getTemplateContent())
                .templateVariables(t.getTemplateVariables())
                .category(t.getCategory())
                .industry(t.getIndustry())
                .isActive(t.getIsActive())
                .isDefault(t.getIsDefault())
                .version(t.getVersion())
                .description(t.getDescription())
                .submitterType(t.getSubmitterType())
                .submitterId(t.getSubmitterId())
                .submitterName(t.getSubmitterName())
                .fileUrl(t.getFileUrl())
                .fileName(t.getFileName())
                .fileSize(t.getFileSize())
                .auditStatus(t.getAuditStatus())
                .auditBy(t.getAuditBy())
                .auditName(t.getAuditName())
                .auditAt(t.getAuditAt())
                .auditNote(t.getAuditNote())
                .usageCount(t.getUsageCount())
                .createdAt(t.getCreatedAt())
                .build();
    }

    @Override
    @Transactional
    public ContractTemplateResponse submitCustomTemplate(Long submitterId, String submitterType, String submitterName,
                                                          ContractTemplateSubmitRequest request) {
        String code = "CUSTOM_" + submitterType + "_" + submitterId + "_" + System.currentTimeMillis();

        ContractTemplate template = ContractTemplate.builder()
                .templateName(request.getTemplateName())
                .templateCode(code)
                .templateType(request.getTemplateType())
                .templateContent(request.getTemplateContent() != null ? request.getTemplateContent() : "")
                .category(request.getCategory())
                .industry(request.getIndustry())
                .description(request.getDescription())
                .fileUrl(request.getFileUrl())
                .fileName(request.getFileName())
                .fileSize(request.getFileSize())
                .submitterType(submitterType)
                .submitterId(submitterId)
                .submitterName(submitterName)
                .auditStatus("PENDING")
                .isActive(false)
                .isDefault(false)
                .createdBy(submitterId)
                .build();

        return toTemplateResponse(templateRepository.save(template));
    }

    @Override
    public List<ContractTemplateResponse> listMyTemplates(Long submitterId, String submitterType) {
        return templateRepository.findBySubmitterTypeAndSubmitterId(submitterType, submitterId)
                .stream().map(this::toTemplateResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public ContractTemplateResponse auditTemplate(Long templateId, Long auditorId, String auditorName,
                                                    ContractTemplateAuditRequest request) {
        ContractTemplate t = templateRepository.findById(templateId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_TEMPLATE_NOT_FOUND));

        if (!"PENDING".equals(t.getAuditStatus())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该模板不在待审核状态");
        }

        t.setAuditStatus(request.isApproved() ? "APPROVED" : "REJECTED");
        t.setAuditBy(auditorId);
        t.setAuditName(auditorName);
        t.setAuditAt(LocalDateTime.now());
        t.setAuditNote(request.getAuditNote());

        if (request.isApproved()) {
            t.setIsActive(true);
        }

        return toTemplateResponse(templateRepository.save(t));
    }

    @Override
    public List<ContractTemplateResponse> listPendingAuditTemplates() {
        return templateRepository.findByAuditStatusOrderByCreatedAtDesc("PENDING")
                .stream().map(this::toTemplateResponse).collect(Collectors.toList());
    }

    @Override
    public List<ContractTemplateResponse> listAllTemplates() {
        return templateRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream().map(this::toTemplateResponse).collect(Collectors.toList());
    }

    // ===== 待签合同相关实现 =====

    @Override
    public List<ContractResponse> listBuyerPendingContracts(Long buyerId) {
        return contractRepository.findPendingSignByBuyerId(buyerId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    public List<ContractResponse> listSupplierPendingContracts(Long supplierId) {
        return contractRepository.findPendingSignBySupplierId(supplierId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    public List<ContractResponse> listPlatformPendingContracts() {
        return contractRepository.findPlatformPendingContracts()
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    public List<ContractResponse> listAllPendingContracts() {
        return contractRepository.findAllPendingContracts()
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public ContractResponse assignSupplier(Long contractId, Long supplierId, String supplierName, Long operatorId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        // 只有平台代采合同才能分配供应商
        if (!"PLATFORM_PROCUREMENT".equals(contract.getProcurementMode())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "只有平台代采合同才能分配供应商");
        }

        // 更新供应商信息
        contract.setSupplierId(supplierId);
        // 可以在remark中记录分配信息
        String remark = contract.getRemark() != null ? contract.getRemark() : "";
        remark += "\n[" + LocalDateTime.now() + "] 平台分配供应商: " + supplierName + " (操作人ID: " + operatorId + ")";
        contract.setRemark(remark);

        return toResponse(contractRepository.save(contract));
    }
}
