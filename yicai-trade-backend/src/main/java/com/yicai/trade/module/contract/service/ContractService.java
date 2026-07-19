package com.yicai.trade.module.contract.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.contract.dto.*;

import java.util.List;

public interface ContractService {

    /**
     * 创建合同（采购商从报价单生成合同）
     */
    ContractResponse createContract(Long buyerId, ContractCreateRequest request);

    /**
     * 获取合同详情（含变更记录）
     */
    ContractResponse getContract(Long contractId);

    /**
     * 通过合同编号获取
     */
    ContractResponse getContractByNo(String contractNo);

    /**
     * 采购商签署合同
     */
    ContractResponse buyerSign(Long contractId, Long buyerId, ContractSignRequest request);

    /**
     * 供应商签署合同
     */
    ContractResponse supplierSign(Long contractId, Long supplierId, ContractSignRequest request);

    /**
     * 双方签署完成后自动生成订单
     */
    Long generateOrderFromContract(Long contractId);

    /**
     * 采购商的合同列表
     */
    PageResult<ContractResponse> listBuyerContracts(Long buyerId, String status, int page, int size);

    /**
     * 供应商的合同列表
     */
    PageResult<ContractResponse> listSupplierContracts(Long supplierId, String status, int page, int size);

    /**
     * 平台审核合同
     */
    ContractResponse platformReview(Long contractId, Long reviewerId, boolean approved, String note);

    /**
     * 发起合同变更
     */
    void requestChange(Long contractId, Long initiatorId, String initiatorType, ContractChangeRequest request);

    /**
     * 审批合同变更
     */
    void approveChange(Long changeLogId, Long approverId, String approverName, boolean approved, String note);

    /**
     * 终止合同
     */
    ContractResponse terminateContract(Long contractId, Long operatorId, String reason);

    /**
     * 完成合同（订单完成后联动）
     */
    ContractResponse completeContract(Long contractId);

    /**
     * 获取合同模板列表
     */
    List<ContractTemplateResponse> listActiveTemplates(String category);

    /**
     * 获取模板详情
     */
    ContractTemplateResponse getTemplate(Long templateId);

    /**
     * 采购商/供应商提交自定义合同模板（待平台审核）
     */
    ContractTemplateResponse submitCustomTemplate(Long submitterId, String submitterType, String submitterName, ContractTemplateSubmitRequest request);

    /**
     * 查询我提交的模板列表
     */
    List<ContractTemplateResponse> listMyTemplates(Long submitterId, String submitterType);

    /**
     * 平台审核自定义模板
     */
    ContractTemplateResponse auditTemplate(Long templateId, Long auditorId, String auditorName, ContractTemplateAuditRequest request);

    /**
     * 查询待审核的模板列表（平台管理员）
     */
    List<ContractTemplateResponse> listPendingAuditTemplates();

    /**
     * 查询全部模板列表（平台管理员，含所有状态）
     */
    List<ContractTemplateResponse> listAllTemplates();

    // ===== 待签合同相关 =====

    /**
     * 获取采购商的待签合同列表
     */
    List<ContractResponse> listBuyerPendingContracts(Long buyerId);

    /**
     * 获取供应商的待签合同列表
     */
    List<ContractResponse> listSupplierPendingContracts(Long supplierId);

    /**
     * 获取平台所有待签合同列表（平台代采模式）
     */
    List<ContractResponse> listPlatformPendingContracts();

    /**
     * 获取所有待签合同列表（平台管理员）
     */
    List<ContractResponse> listAllPendingContracts();

    /**
     * 平台为代采合同分配供应商
     */
    ContractResponse assignSupplier(Long contractId, Long supplierId, String supplierName, Long operatorId);

    /**
     * 上传纸质合同扫描件
     */
    ContractResponse uploadPhysicalContract(Long contractId, Long userId, String physicalContractUrl);

    /**
     * 平台审核纸质合同（审核通过后订单才触发执行）
     */
    ContractResponse reviewPhysicalContract(Long contractId, Long reviewerId, boolean approved, String note);

    /**
     * 获取待审核纸质合同列表
     */
    List<ContractResponse> listPendingPhysicalReview();
}
