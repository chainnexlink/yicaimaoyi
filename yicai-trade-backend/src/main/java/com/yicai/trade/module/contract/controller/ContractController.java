package com.yicai.trade.module.contract.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.contract.dto.*;
import com.yicai.trade.module.contract.service.ContractService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contracts")
@RequiredArgsConstructor
@Tag(name = "ContractManagement", description = "合同管理")
public class ContractController {

    private final ContractService contractService;
    private final ResourceAuthorizationService authorizationService;

    // ===== 采购商操作 =====

    @PostMapping
    @Operation(summary = "创建合同", description = "采购商从报价单生成合同草稿")
    public Result<ContractResponse> createContract(
            @RequestParam Long buyerId,
            @RequestBody @Valid ContractCreateRequest request) {
        authorizationService.assertBuyerAccess(buyerId);
        return Result.success(contractService.createContract(buyerId, request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取合同详情", description = "含变更记录")
    public Result<ContractResponse> getContract(@PathVariable Long id) {
        authorizationService.assertContractAccess(id);
        return Result.success(contractService.getContract(id));
    }

    @GetMapping("/no/{contractNo}")
    @Operation(summary = "通过合同编号查询")
    public Result<ContractResponse> getContractByNo(@PathVariable String contractNo) {
        authorizationService.assertContractNumberAccess(contractNo);
        return Result.success(contractService.getContractByNo(contractNo));
    }

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "采购商合同列表")
    public Result<PageResult<ContractResponse>> listBuyerContracts(
            @PathVariable Long buyerId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        authorizationService.assertBuyerAccess(buyerId);
        return Result.success(contractService.listBuyerContracts(buyerId, status, page, size));
    }

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "供应商合同列表")
    public Result<PageResult<ContractResponse>> listSupplierContracts(
            @PathVariable Long supplierId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        authorizationService.assertSupplierAccess(supplierId);
        return Result.success(contractService.listSupplierContracts(supplierId, status, page, size));
    }

    // ===== 签署操作 =====

    @PostMapping("/{id}/sign/buyer")
    @Operation(summary = "采购商签署合同")
    public Result<ContractResponse> buyerSign(
            @PathVariable Long id,
            @RequestParam Long buyerId,
            @RequestBody @Valid ContractSignRequest request) {
        authorizationService.assertBuyerAccess(buyerId);
        authorizationService.assertContractAccess(id);
        return Result.success(contractService.buyerSign(id, buyerId, request));
    }

    @PostMapping("/{id}/sign/supplier")
    @Operation(summary = "供应商签署合同")
    public Result<ContractResponse> supplierSign(
            @PathVariable Long id,
            @RequestParam Long supplierId,
            @RequestBody @Valid ContractSignRequest request) {
        authorizationService.assertSupplierAccess(supplierId);
        authorizationService.assertContractAccess(id);
        return Result.success(contractService.supplierSign(id, supplierId, request));
    }

    @PostMapping("/{id}/generate-order")
    @Operation(summary = "合同生成订单", description = "双方签署完成后生成采购订单")
    public Result<Long> generateOrder(@PathVariable Long id) {
        authorizationService.assertContractAccess(id);
        return Result.success(contractService.generateOrderFromContract(id));
    }

    // ===== 合同变更 =====

    @PostMapping("/{id}/changes")
    @Operation(summary = "发起合同变更")
    public Result<Void> requestChange(
            @PathVariable Long id,
            @RequestParam Long initiatorId,
            @RequestParam String initiatorType,
            @RequestBody @Valid ContractChangeRequest request) {
        authorizationService.assertPartyAccess(initiatorType, initiatorId);
        authorizationService.assertContractAccess(id);
        contractService.requestChange(id, initiatorId, initiatorType, request);
        return Result.success();
    }

    @PutMapping("/changes/{changeLogId}/approve")
    @Operation(summary = "审批合同变更")
    public Result<Void> approveChange(
            @PathVariable Long changeLogId,
            @RequestParam Long approverId,
            @RequestParam String approverName,
            @RequestParam boolean approved,
            @RequestParam(required = false) String note) {
        contractService.approveChange(changeLogId, approverId, approverName, approved, note);
        return Result.success();
    }

    // ===== 合同状态操作 =====

    @PutMapping("/{id}/terminate")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "终止合同")
    public Result<ContractResponse> terminateContract(
            @PathVariable Long id,
            @RequestParam Long operatorId,
            @RequestParam String reason) {
        return Result.success(contractService.terminateContract(id, operatorId, reason));
    }

    @PutMapping("/{id}/complete")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "完成合同", description = "订单完成后联动完成合同")
    public Result<ContractResponse> completeContract(@PathVariable Long id) {
        return Result.success(contractService.completeContract(id));
    }

    // ===== 平台审核 =====

    @PutMapping("/{id}/review")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "平台审核合同")
    public Result<ContractResponse> platformReview(
            @PathVariable Long id,
            @RequestParam Long reviewerId,
            @RequestParam boolean approved,
            @RequestParam(required = false) String note) {
        return Result.success(contractService.platformReview(id, reviewerId, approved, note));
    }

    // ===== 合同模板 =====

    @GetMapping("/templates")
    @Operation(summary = "获取合同模板列表")
    public Result<List<ContractTemplateResponse>> listTemplates(
            @RequestParam(required = false) String category) {
        return Result.success(contractService.listActiveTemplates(category));
    }

    @GetMapping("/templates/{templateId}")
    @Operation(summary = "获取模板详情")
    public Result<ContractTemplateResponse> getTemplate(@PathVariable Long templateId) {
        return Result.success(contractService.getTemplate(templateId));
    }

    // ===== 自定义合同模板上传与审核 =====

    @PostMapping("/templates/submit")
    @Operation(summary = "提交自定义合同模板", description = "采购商/供应商上传自定义合同模板，提交平台审核")
    public Result<ContractTemplateResponse> submitCustomTemplate(
            @RequestParam Long submitterId,
            @RequestParam String submitterType,
            @RequestParam String submitterName,
            @RequestBody @Valid ContractTemplateSubmitRequest request) {
        authorizationService.assertPartyAccess(submitterType, submitterId);
        return Result.success(contractService.submitCustomTemplate(submitterId, submitterType, submitterName, request));
    }

    @GetMapping("/templates/my")
    @Operation(summary = "查询我提交的模板列表", description = "采购商/供应商查看自己提交的模板及审核状态")
    public Result<List<ContractTemplateResponse>> listMyTemplates(
            @RequestParam Long submitterId,
            @RequestParam String submitterType) {
        authorizationService.assertPartyAccess(submitterType, submitterId);
        return Result.success(contractService.listMyTemplates(submitterId, submitterType));
    }

    @PutMapping("/templates/{templateId}/audit")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "平台审核自定义模板", description = "平台管理员审核采购商/供应商提交的合同模板")
    public Result<ContractTemplateResponse> auditTemplate(
            @PathVariable Long templateId,
            @RequestParam Long auditorId,
            @RequestParam String auditorName,
            @RequestBody @Valid ContractTemplateAuditRequest request) {
        return Result.success(contractService.auditTemplate(templateId, auditorId, auditorName, request));
    }

    @GetMapping("/templates/pending")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "查询待审核模板列表", description = "平台管理员获取待审核的自定义模板")
    public Result<List<ContractTemplateResponse>> listPendingAuditTemplates() {
        return Result.success(contractService.listPendingAuditTemplates());
    }

    @GetMapping("/templates/all")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "查询全部模板", description = "平台管理员获取所有模板，含各种审核状态")
    public Result<List<ContractTemplateResponse>> listAllTemplates() {
        return Result.success(contractService.listAllTemplates());
    }

    // ===== 待签合同管理（三角色闭环）=====

    @GetMapping("/pending/buyer/{buyerId}")
    @Operation(summary = "采购商待签合同列表", description = "获取采购商需要签署的合同")
    public Result<List<ContractResponse>> listBuyerPendingContracts(@PathVariable Long buyerId) {
        authorizationService.assertBuyerAccess(buyerId);
        return Result.success(contractService.listBuyerPendingContracts(buyerId));
    }

    @GetMapping("/pending/supplier/{supplierId}")
    @Operation(summary = "供应商待签合同列表", description = "获取供应商需要签署的合同")
    public Result<List<ContractResponse>> listSupplierPendingContracts(@PathVariable Long supplierId) {
        authorizationService.assertSupplierAccess(supplierId);
        return Result.success(contractService.listSupplierPendingContracts(supplierId));
    }

    @GetMapping("/pending/platform")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "平台代采待签合同列表", description = "获取平台代采模式的待签合同")
    public Result<List<ContractResponse>> listPlatformPendingContracts() {
        return Result.success(contractService.listPlatformPendingContracts());
    }

    @GetMapping("/pending/all")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "所有待签合同列表", description = "平台管理员获取所有待签合同")
    public Result<List<ContractResponse>> listAllPendingContracts() {
        return Result.success(contractService.listAllPendingContracts());
    }

    @PutMapping("/{id}/assign-supplier")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "分配供应商", description = "平台为代采合同分配实际供应商")
    public Result<ContractResponse> assignSupplier(
            @PathVariable Long id,
            @RequestParam Long supplierId,
            @RequestParam String supplierName,
            @RequestParam Long operatorId) {
        return Result.success(contractService.assignSupplier(id, supplierId, supplierName, operatorId));
    }

    // ===== 纸质合同上传与审核 =====

    @PostMapping("/{id}/upload-physical-contract")
    @Operation(summary = "上传纸质合同扫描件", description = "双方签署后上传纸质合同扫描件，提交平台审核")
    public Result<ContractResponse> uploadPhysicalContract(
            @PathVariable Long id,
            @RequestParam Long userId,
            @RequestParam String physicalContractUrl) {
        authorizationService.assertContractPartyAccess(id, userId);
        return Result.success(contractService.uploadPhysicalContract(id, userId, physicalContractUrl));
    }

    @PutMapping("/{id}/review-physical-contract")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "审核纸质合同", description = "平台审核纸质合同，通过后订单触发执行")
    public Result<ContractResponse> reviewPhysicalContract(
            @PathVariable Long id,
            @RequestParam Long reviewerId,
            @RequestParam boolean approved,
            @RequestParam(required = false) String note) {
        return Result.success(contractService.reviewPhysicalContract(id, reviewerId, approved, note));
    }

    @GetMapping("/pending-physical-review")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "待审核纸质合同列表", description = "平台管理员获取待审核的纸质合同")
    public Result<List<ContractResponse>> listPendingPhysicalReview() {
        return Result.success(contractService.listPendingPhysicalReview());
    }
}
