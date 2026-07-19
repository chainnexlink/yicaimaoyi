package com.yicai.trade.module.inquiry.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.inquiry.dto.*;
import com.yicai.trade.module.inquiry.service.InquiryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/inquiries")
@RequiredArgsConstructor
@Tag(name = "InquiryManagement")
public class InquiryController {

    private final InquiryService inquiryService;

    @PostMapping
    @Operation(summary = "Create inquiry")
    public Result<InquiryResponse> createInquiry(@RequestParam Long buyerId,
                                                  @RequestBody @Valid InquiryCreateRequest request) {
        return Result.success(inquiryService.createInquiry(buyerId, request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get inquiry")
    public Result<InquiryResponse> getInquiry(@PathVariable Long id) {
        return Result.success(inquiryService.getInquiry(id));
    }

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "Buyer inquiries")
    public Result<PageResult<InquiryResponse>> listBuyerInquiries(
            @PathVariable Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(inquiryService.listBuyerInquiries(buyerId, page, size));
    }

    @GetMapping("/open")
    @Operation(summary = "Open inquiries")
    public Result<PageResult<InquiryResponse>> listOpenInquiries(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(inquiryService.listOpenInquiries(page, size));
    }

    @PostMapping("/{id}/close")
    @Operation(summary = "Close inquiry")
    public Result<Void> closeInquiry(@PathVariable Long id) {
        inquiryService.closeInquiry(id);
        return Result.success();
    }

    @PostMapping("/quotations")
    @Operation(summary = "Submit quotation")
    public Result<QuotationResponse> submitQuotation(@RequestParam Long supplierId,
                                                      @RequestBody @Valid QuotationCreateRequest request) {
        return Result.success(inquiryService.submitQuotation(supplierId, request));
    }

    @GetMapping("/quotations/supplier/{supplierId}")
    @Operation(summary = "Supplier quotations")
    public Result<PageResult<QuotationResponse>> listSupplierQuotations(
            @PathVariable Long supplierId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(inquiryService.listSupplierQuotations(supplierId, page, size));
    }

    @PostMapping("/quotations/{quotationId}/accept")
    @Operation(summary = "Accept quotation", description = "采购商接受报价，自动关闭询价、拒绝其他报价")
    public Result<QuotationResponse> acceptQuotation(
            @PathVariable Long quotationId,
            @RequestParam Long buyerId) {
        return Result.success(inquiryService.acceptQuotation(quotationId, buyerId));
    }
}
