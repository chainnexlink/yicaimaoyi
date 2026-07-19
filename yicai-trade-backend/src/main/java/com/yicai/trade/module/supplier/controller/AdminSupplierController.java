package com.yicai.trade.module.supplier.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.supplier.dto.SupplierResponse;
import com.yicai.trade.module.supplier.service.SupplierService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/suppliers")
@RequiredArgsConstructor
@Tag(name = "AdminSupplier")
public class AdminSupplierController {

    private final SupplierService supplierService;

    @GetMapping
    @Operation(summary = "list suppliers")
    public Result<PageResult<SupplierResponse>> listSuppliers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(supplierService.listSuppliers(keyword, status, page, size));
    }

    @PostMapping("/applications/{id}/audit")
    @Operation(summary = "audit application")
    public Result<Void> auditApplication(@PathVariable Long id, @RequestBody Map<String, String> body) {
        supplierService.auditApplication(id, body.get("action"), body.get("rejectReason"), 1L);
        return Result.success();
    }
}
