package com.yicai.trade.module.invoice.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.invoice.dto.InvoiceCreateRequest;
import com.yicai.trade.module.invoice.dto.InvoiceResponse;

import java.util.Map;

public interface InvoiceService {
    InvoiceResponse create(InvoiceCreateRequest request);
    InvoiceResponse getById(Long id);
    InvoiceResponse getByInvoiceNo(String invoiceNo);
    PageResult<InvoiceResponse> list(String status, Long supplierId, Long buyerId, int page, int size);
    PageResult<InvoiceResponse> listByOrder(Long orderId, int page, int size);
    void issue(Long id, String fileUrl);
    void send(Long id);
    void confirmReceived(Long id);
    void cancel(Long id, String reason);
    void voidInvoice(Long id, String reason);
    Map<String, Long> getStats();
}
