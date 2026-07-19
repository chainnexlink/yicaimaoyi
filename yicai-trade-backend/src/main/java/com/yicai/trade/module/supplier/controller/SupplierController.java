package com.yicai.trade.module.supplier.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.supplier.dto.*;
import com.yicai.trade.module.supplier.service.SupplierService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/supplier")
@RequiredArgsConstructor
@Tag(name = "SupplierCenter")
public class SupplierController {

    private final SupplierService supplierService;

    @PostMapping("/apply")
    @Operation(summary = "Submit application")
    public Result<Void> apply(@RequestBody @Valid SupplierApplicationRequest request,
                              @AuthenticationPrincipal UserDetails user) {
        supplierService.submitApplication(Long.parseLong(user.getUsername()), request);
        return Result.success();
    }

    @GetMapping("/profile")
    @Operation(summary = "Get supplier profile")
    public Result<SupplierResponse> getProfile(@AuthenticationPrincipal UserDetails user) {
        return Result.success(supplierService.getSupplierByUserId(Long.parseLong(user.getUsername())));
    }

    @PutMapping("/profile")
    @Operation(summary = "Update supplier profile")
    public Result<SupplierResponse> updateProfile(@RequestBody SupplierApplicationRequest request,
                                                  @AuthenticationPrincipal UserDetails user) {
        return Result.success(supplierService.updateSupplier(Long.parseLong(user.getUsername()), request));
    }

    @PostMapping("/products")
    @Operation(summary = "Add product")
    public Result<ProductResponse> addProduct(@RequestBody @Valid ProductRequest request,
                                              @RequestParam Long supplierId) {
        return Result.success(supplierService.addProduct(supplierId, request));
    }

    @PutMapping("/products/{id}")
    @Operation(summary = "Update product")
    public Result<ProductResponse> updateProduct(@PathVariable Long id, @RequestBody ProductRequest request) {
        return Result.success(supplierService.updateProduct(id, request));
    }

    @DeleteMapping("/products/{id}")
    @Operation(summary = "Delete product")
    public Result<Void> deleteProduct(@PathVariable Long id) {
        supplierService.deleteProduct(id);
        return Result.success();
    }

    @GetMapping("/products")
    @Operation(summary = "List products")
    public Result<PageResult<ProductResponse>> listProducts(
            @RequestParam Long supplierId,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(supplierService.listProducts(supplierId, keyword, page, size));
    }
}
