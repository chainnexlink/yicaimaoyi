package com.yicai.trade.module.inquiry.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.inquiry.dto.*;

public interface InquiryService {
    InquiryResponse createInquiry(Long buyerId, InquiryCreateRequest request);
    InquiryResponse getInquiry(Long inquiryId);
    PageResult<InquiryResponse> listBuyerInquiries(Long buyerId, int page, int size);
    PageResult<InquiryResponse> listOpenInquiries(int page, int size);
    void closeInquiry(Long inquiryId);
    QuotationResponse submitQuotation(Long supplierId, QuotationCreateRequest request);
    PageResult<QuotationResponse> listSupplierQuotations(Long supplierId, int page, int size);

    /** 采购商接受报价（报价ACCEPTED，询价CLOSED，其余报价REJECTED） */
    QuotationResponse acceptQuotation(Long quotationId, Long buyerId);
}
