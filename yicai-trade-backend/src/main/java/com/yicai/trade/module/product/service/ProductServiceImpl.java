package com.yicai.trade.module.product.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.product.dto.*;
import com.yicai.trade.module.product.entity.Product;
import com.yicai.trade.module.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;

    @Override
    @Transactional
    public ProductResponse createProduct(ProductRequest request) {
        Product product = Product.builder()
                .productNo("PRD" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")))
                .name(request.getName())
                .supplierId(request.getSupplierId())
                .supplierName(request.getSupplierName())
                .category(request.getCategory())
                .price(request.getPrice())
                .minOrderQuantity(request.getMinOrderQuantity())
                .unit(request.getUnit())
                .stock(request.getStock())
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .auditStatus("PENDING")
                .build();
        return toResponse(productRepository.save(product));
    }

    @Override
    @Transactional
    public ProductResponse updateProduct(Long id, ProductRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found: " + id));
        product.setName(request.getName());
        product.setSupplierId(request.getSupplierId());
        product.setSupplierName(request.getSupplierName());
        product.setCategory(request.getCategory());
        product.setPrice(request.getPrice());
        product.setMinOrderQuantity(request.getMinOrderQuantity());
        product.setUnit(request.getUnit());
        product.setStock(request.getStock());
        product.setDescription(request.getDescription());
        product.setImageUrl(request.getImageUrl());
        return toResponse(productRepository.save(product));
    }

    @Override
    @Transactional
    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
    }

    @Override
    public ProductResponse getProduct(Long id) {
        return productRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("Product not found: " + id));
    }

    @Override
    public PageResult<ProductResponse> listProducts(String auditStatus, String category, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Product> productPage;
        if (auditStatus != null && !auditStatus.isEmpty() && category != null && !category.isEmpty()) {
            productPage = productRepository.findByAuditStatusAndCategory(auditStatus, category, pageable);
        } else if (auditStatus != null && !auditStatus.isEmpty()) {
            productPage = productRepository.findByAuditStatus(auditStatus, pageable);
        } else if (category != null && !category.isEmpty()) {
            productPage = productRepository.findByCategory(category, pageable);
        } else {
            productPage = productRepository.findAll(pageable);
        }
        List<ProductResponse> list = productPage.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, productPage.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void auditProduct(Long id, String action, String remark) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found: " + id));
        product.setAuditStatus("APPROVE".equals(action) ? "APPROVED" : "REJECTED");
        product.setAuditRemark(remark);
        productRepository.save(product);
    }

    @Override
    public Map<String, Long> getProductStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", productRepository.count());
        stats.put("pending", productRepository.countByAuditStatus("PENDING"));
        stats.put("approved", productRepository.countByAuditStatus("APPROVED"));
        stats.put("rejected", productRepository.countByAuditStatus("REJECTED"));
        return stats;
    }

    private ProductResponse toResponse(Product product) {
        ProductResponse r = new ProductResponse();
        r.setId(product.getId());
        r.setProductNo(product.getProductNo());
        r.setName(product.getName());
        r.setSupplierId(product.getSupplierId());
        r.setSupplierName(product.getSupplierName());
        r.setCategory(product.getCategory());
        r.setPrice(product.getPrice());
        r.setMinOrderQuantity(product.getMinOrderQuantity());
        r.setUnit(product.getUnit());
        r.setStock(product.getStock());
        r.setDescription(product.getDescription());
        r.setImageUrl(product.getImageUrl());
        r.setAuditStatus(product.getAuditStatus());
        r.setAuditRemark(product.getAuditRemark());
        r.setCreatedAt(product.getCreatedAt());
        r.setUpdatedAt(product.getUpdatedAt());
        return r;
    }
}
