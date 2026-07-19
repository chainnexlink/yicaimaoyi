package com.yicai.trade.module.invoice.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class InvoiceResponse {
    private Long id;
    private String invoiceNo;
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
    private BigDecimal taxAmount;
    private BigDecimal totalAmount;
    private String currency;
    private String title;
    private String taxNo;
    private String bankName;
    private String bankAccount;
    private String registerAddress;
    private String registerPhone;
    private String fileUrl;
    private LocalDate issueDate;
    private String status;
    private String remark;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
