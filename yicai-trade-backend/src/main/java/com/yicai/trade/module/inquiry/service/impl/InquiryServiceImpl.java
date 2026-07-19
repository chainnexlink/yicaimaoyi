package com.yicai.trade.module.inquiry.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.inquiry.dto.*;
import com.yicai.trade.module.inquiry.entity.Inquiry;
import com.yicai.trade.module.inquiry.entity.Quotation;
import com.yicai.trade.module.inquiry.repository.InquiryRepository;
import com.yicai.trade.module.inquiry.repository.QuotationRepository;
import com.yicai.trade.module.inquiry.service.InquiryService;
import com.yicai.trade.module.contract.dto.ContractCreateRequest;
import com.yicai.trade.module.contract.service.ContractService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class InquiryServiceImpl implements InquiryService {

    private final InquiryRepository inquiryRepository;
    private final QuotationRepository quotationRepository;
    private final ContractService contractService;

    @Override
    @Transactional
    @SuppressWarnings("null")
    public InquiryResponse createInquiry(Long buyerId, InquiryCreateRequest request) {
        @lombok.NonNull Inquiry inquiry = Inquiry.builder()
                .buyerId(buyerId).title(request.getTitle())
                .description(request.getDescription())
                .productCategory(request.getProductCategory())
                .expectedQuantity(request.getExpectedQuantity())
                .unit(request.getUnit()).deadline(request.getDeadline())
                .status("OPEN").build();
        return toResponse(inquiryRepository.save(inquiry), null);
    }

    @Override
    @SuppressWarnings("null")
    public InquiryResponse getInquiry(@lombok.NonNull Long inquiryId) {
        Inquiry inquiry = inquiryRepository.findById(inquiryId)
                .orElseThrow(() -> new BusinessException(ErrorCode.INQUIRY_NOT_FOUND));
        return toResponse(inquiry, quotationRepository.findByInquiryId(inquiryId));
    }

    @Override
    public PageResult<InquiryResponse> listBuyerInquiries(Long buyerId, int page, int size) {
        Page<Inquiry> p = inquiryRepository.findByBuyerId(buyerId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(p.getContent().stream().map(i -> toResponse(i, null)).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<InquiryResponse> listOpenInquiries(int page, int size) {
        Page<Inquiry> p = inquiryRepository.findByStatus("OPEN",
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(p.getContent().stream().map(i -> toResponse(i, null)).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void closeInquiry(@lombok.NonNull Long inquiryId) {
        Inquiry inquiry = inquiryRepository.findById(inquiryId)
                .orElseThrow(() -> new BusinessException(ErrorCode.INQUIRY_NOT_FOUND));
        if (!"OPEN".equals(inquiry.getStatus())) {
            throw new BusinessException(ErrorCode.INQUIRY_CLOSED);
        }
        inquiry.setStatus("CLOSED");
        inquiryRepository.save(inquiry);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public QuotationResponse submitQuotation(Long supplierId, QuotationCreateRequest request) {
        inquiryRepository.findById(request.getInquiryId())
                .filter(i -> "OPEN".equals(i.getStatus()))
                .orElseThrow(() -> new BusinessException(ErrorCode.INQUIRY_CLOSED));
        @lombok.NonNull Quotation q = Quotation.builder()
                .inquiryId(request.getInquiryId()).supplierId(supplierId)
                .unitPrice(request.getUnitPrice()).totalPrice(request.getTotalPrice())
                .deliveryDays(request.getDeliveryDays()).description(request.getDescription())
                .status("SUBMITTED").build();
        return toQResponse(quotationRepository.save(q));
    }

    @Override
    public PageResult<QuotationResponse> listSupplierQuotations(Long supplierId, int page, int size) {
        Page<Quotation> p = quotationRepository.findBySupplierId(supplierId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(p.getContent().stream().map(this::toQResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public QuotationResponse acceptQuotation(@lombok.NonNull Long quotationId, Long buyerId) {
        Quotation quotation = quotationRepository.findById(quotationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.QUOTATION_NOT_FOUND));

        Inquiry inquiry = inquiryRepository.findById(quotation.getInquiryId())
                .orElseThrow(() -> new BusinessException(ErrorCode.INQUIRY_NOT_FOUND));

        // 校验：必须是该询价的发起人
        if (!inquiry.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        // 校验：询价必须是开放状态
        if (!"OPEN".equals(inquiry.getStatus())) {
            throw new BusinessException(ErrorCode.INQUIRY_CLOSED);
        }
        // 校验：不能重复接受
        if ("ACCEPTED".equals(quotation.getStatus())) {
            throw new BusinessException(ErrorCode.QUOTATION_ALREADY_ACCEPTED);
        }

        // 将该报价设为ACCEPTED
        quotation.setStatus("ACCEPTED");
        quotationRepository.save(quotation);

        // 将同一询价下其他报价设为REJECTED
        List<Quotation> otherQuotations = quotationRepository.findByInquiryId(inquiry.getId());
        for (Quotation q : otherQuotations) {
            if (!q.getId().equals(quotationId) && "SUBMITTED".equals(q.getStatus())) {
                q.setStatus("REJECTED");
                quotationRepository.save(q);
            }
        }

        // 关闭询价
        inquiry.setStatus("CLOSED");
        inquiryRepository.save(inquiry);

        // ===== 自动创建合同 =====
        try {
            ContractCreateRequest contractReq = new ContractCreateRequest();
            contractReq.setInquiryId(inquiry.getId());
            contractReq.setQuotationId(quotationId);
            contractReq.setSupplierId(quotation.getSupplierId());
            contractReq.setTotalAmount(quotation.getTotalPrice());
            contractReq.setContractTitle("基于询价「" + inquiry.getTitle() + "」的采购合同");
            if (quotation.getDeliveryDays() != null) {
                contractReq.setDeliveryDate(java.time.LocalDate.now().plusDays(quotation.getDeliveryDays()));
            }
            contractService.createContract(buyerId, contractReq);
            log.info("接受报价后自动创建合同: inquiryId={}, quotationId={}, supplierId={}",
                    inquiry.getId(), quotationId, quotation.getSupplierId());
        } catch (Exception e) {
            log.warn("自动创建合同失败（可手动创建）: quotationId={}, error={}", quotationId, e.getMessage());
        }

        return toQResponse(quotation);
    }

    private InquiryResponse toResponse(Inquiry i, List<Quotation> qs) {
        List<QuotationResponse> qrs = qs != null
                ? qs.stream().map(this::toQResponse).collect(Collectors.toList()) : null;
        return InquiryResponse.builder()
                .id(i.getId()).buyerId(i.getBuyerId()).title(i.getTitle())
                .description(i.getDescription()).productCategory(i.getProductCategory())
                .expectedQuantity(i.getExpectedQuantity()).unit(i.getUnit())
                .status(i.getStatus()).deadline(i.getDeadline())
                .quotations(qrs).createdAt(i.getCreatedAt()).build();
    }

    private QuotationResponse toQResponse(Quotation q) {
        return QuotationResponse.builder()
                .id(q.getId()).inquiryId(q.getInquiryId()).supplierId(q.getSupplierId())
                .unitPrice(q.getUnitPrice()).totalPrice(q.getTotalPrice())
                .deliveryDays(q.getDeliveryDays()).description(q.getDescription())
                .status(q.getStatus()).createdAt(q.getCreatedAt()).build();
    }
}
