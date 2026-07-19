package com.yicai.trade.module.invoice.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.invoice.dto.InvoiceCreateRequest;
import com.yicai.trade.module.invoice.dto.InvoiceResponse;
import com.yicai.trade.module.invoice.entity.Invoice;
import com.yicai.trade.module.invoice.repository.InvoiceRepository;
import com.yicai.trade.module.invoice.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InvoiceServiceImpl implements InvoiceService {

    private final InvoiceRepository invoiceRepository;

    @Override
    @Transactional
    public InvoiceResponse create(InvoiceCreateRequest req) {
        BigDecimal taxRate = req.getTaxRate() != null ? req.getTaxRate() : new BigDecimal("0.13");
        BigDecimal amount = req.getAmount() != null ? req.getAmount() : BigDecimal.ZERO;
        BigDecimal taxAmount = amount.multiply(taxRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal totalAmount = amount.add(taxAmount);

        Invoice invoice = Invoice.builder()
                .invoiceNo("INV" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmssSSS")))
                .orderId(req.getOrderId())
                .orderNo(req.getOrderNo())
                .contractId(req.getContractId())
                .buyerId(req.getBuyerId())
                .buyerName(req.getBuyerName())
                .supplierId(req.getSupplierId())
                .supplierName(req.getSupplierName())
                .invoiceType(req.getInvoiceType() != null ? req.getInvoiceType() : "NORMAL")
                .amount(amount)
                .taxRate(taxRate)
                .taxAmount(taxAmount)
                .totalAmount(totalAmount)
                .currency(req.getCurrency() != null ? req.getCurrency() : "CNY")
                .title(req.getTitle())
                .taxNo(req.getTaxNo())
                .bankName(req.getBankName())
                .bankAccount(req.getBankAccount())
                .registerAddress(req.getRegisterAddress())
                .registerPhone(req.getRegisterPhone())
                .remark(req.getRemark())
                .status("PENDING")
                .build();
        return toResponse(invoiceRepository.save(invoice));
    }

    @Override
    public InvoiceResponse getById(Long id) {
        return invoiceRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + id));
    }

    @Override
    public InvoiceResponse getByInvoiceNo(String invoiceNo) {
        return invoiceRepository.findByInvoiceNo(invoiceNo).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + invoiceNo));
    }

    @Override
    public PageResult<InvoiceResponse> list(String status, Long supplierId, Long buyerId, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Invoice> p;
        if (status != null && !status.isEmpty()) {
            p = invoiceRepository.findByStatus(status, pageable);
        } else if (supplierId != null) {
            p = invoiceRepository.findBySupplierId(supplierId, pageable);
        } else if (buyerId != null) {
            p = invoiceRepository.findByBuyerId(buyerId, pageable);
        } else {
            p = invoiceRepository.findAll(pageable);
        }
        List<InvoiceResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<InvoiceResponse> listByOrder(Long orderId, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Invoice> p = invoiceRepository.findByOrderId(orderId, pageable);
        List<InvoiceResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void issue(Long id, String fileUrl) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + id));
        if (!"PENDING".equals(inv.getStatus())) {
            throw new RuntimeException("只有待开具状态的发票可以开具");
        }
        inv.setStatus("ISSUED");
        inv.setFileUrl(fileUrl);
        inv.setIssueDate(LocalDate.now());
        invoiceRepository.save(inv);
    }

    @Override
    @Transactional
    public void send(Long id) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + id));
        if (!"ISSUED".equals(inv.getStatus())) {
            throw new RuntimeException("只有已开具状态的发票可以发送");
        }
        inv.setStatus("SENT");
        invoiceRepository.save(inv);
    }

    @Override
    @Transactional
    public void confirmReceived(Long id) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + id));
        if (!"SENT".equals(inv.getStatus())) {
            throw new RuntimeException("只有已发送状态的发票可以确认收到");
        }
        inv.setStatus("RECEIVED");
        invoiceRepository.save(inv);
    }

    @Override
    @Transactional
    public void cancel(Long id, String reason) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + id));
        inv.setStatus("CANCELLED");
        inv.setRemark(reason);
        invoiceRepository.save(inv);
    }

    @Override
    @Transactional
    public void voidInvoice(Long id, String reason) {
        Invoice inv = invoiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("发票不存在: " + id));
        inv.setStatus("VOID");
        inv.setRemark("作废原因: " + reason);
        invoiceRepository.save(inv);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", invoiceRepository.count());
        stats.put("pending", invoiceRepository.countByStatus("PENDING"));
        stats.put("issued", invoiceRepository.countByStatus("ISSUED"));
        stats.put("sent", invoiceRepository.countByStatus("SENT"));
        stats.put("received", invoiceRepository.countByStatus("RECEIVED"));
        return stats;
    }

    private InvoiceResponse toResponse(Invoice inv) {
        InvoiceResponse r = new InvoiceResponse();
        r.setId(inv.getId());
        r.setInvoiceNo(inv.getInvoiceNo());
        r.setOrderId(inv.getOrderId());
        r.setOrderNo(inv.getOrderNo());
        r.setContractId(inv.getContractId());
        r.setBuyerId(inv.getBuyerId());
        r.setBuyerName(inv.getBuyerName());
        r.setSupplierId(inv.getSupplierId());
        r.setSupplierName(inv.getSupplierName());
        r.setInvoiceType(inv.getInvoiceType());
        r.setAmount(inv.getAmount());
        r.setTaxRate(inv.getTaxRate());
        r.setTaxAmount(inv.getTaxAmount());
        r.setTotalAmount(inv.getTotalAmount());
        r.setCurrency(inv.getCurrency());
        r.setTitle(inv.getTitle());
        r.setTaxNo(inv.getTaxNo());
        r.setBankName(inv.getBankName());
        r.setBankAccount(inv.getBankAccount());
        r.setRegisterAddress(inv.getRegisterAddress());
        r.setRegisterPhone(inv.getRegisterPhone());
        r.setFileUrl(inv.getFileUrl());
        r.setIssueDate(inv.getIssueDate());
        r.setStatus(inv.getStatus());
        r.setRemark(inv.getRemark());
        r.setCreatedAt(inv.getCreatedAt());
        r.setUpdatedAt(inv.getUpdatedAt());
        return r;
    }
}
