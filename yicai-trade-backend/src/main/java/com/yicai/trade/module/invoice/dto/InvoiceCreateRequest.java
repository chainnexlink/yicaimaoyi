package com.yicai.trade.module.invoice.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class InvoiceCreateRequest {
    private Long orderId;
    private String orderNo;
    private Long contractId;
    private Long buyerId;
    private String buyerName;
    private Long supplierId;
    private String supplierName;
    private String invoiceType;
    private BigDecimal amount;
    private BigDecimal taxRate;
    private String currency;
    private String title;
    private String taxNo;
    private String bankName;
    private String bankAccount;
    private String registerAddress;
    private String registerPhone;
    private String remark;
}
