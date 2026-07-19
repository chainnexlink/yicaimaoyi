package com.yicai.trade.module.product.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.product.dto.*;
import com.yicai.trade.module.product.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/products")
@RequiredArgsConstructor
@Tag(name = "产品管理", description = "产品审核与管理接口")
public class ProductController {

    private final ProductService productService;

    @PostMapping
    @Operation(summary = "创建产品")
    public Result<ProductResponse> create(@Valid @RequestBody ProductRequest request) {
        return Result.success(productService.createProduct(request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新产品")
    public Result<ProductResponse> update(@PathVariable Long id, @Valid @RequestBody ProductRequest request) {
        return Result.success(productService.updateProduct(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除产品")
    public Result<Void> delete(@PathVariable Long id) {
        productService.deleteProduct(id);
        return Result.success(null);
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取产品详情")
    public Result<ProductResponse> get(@PathVariable Long id) {
        return Result.success(productService.getProduct(id));
    }

    @GetMapping
    @Operation(summary = "分页查询产品列表")
    public Result<PageResult<ProductResponse>> list(
            @RequestParam(required = false) String auditStatus,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(productService.listProducts(auditStatus, category, page, size));
    }

    @PostMapping("/{id}/audit")
    @Operation(summary = "审核产品")
    public Result<Void> audit(@PathVariable Long id, @RequestBody Map<String, String> body) {
        productService.auditProduct(id, body.get("action"), body.get("remark"));
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "产品统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(productService.getProductStats());
    }
}
