package com.yicai.trade.module.supplier.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.supplier.dto.*;
import com.yicai.trade.module.supplier.entity.Supplier;
import com.yicai.trade.module.supplier.entity.SupplierApplication;
import com.yicai.trade.module.supplier.entity.SupplierProduct;
import com.yicai.trade.module.supplier.repository.SupplierApplicationRepository;
import com.yicai.trade.module.supplier.repository.SupplierProductRepository;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import com.yicai.trade.module.supplier.service.SupplierService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SupplierServiceImpl implements SupplierService {

    private final SupplierRepository supplierRepository;
    private final SupplierApplicationRepository applicationRepository;
    private final UserRepository userRepository;
    private final SupplierProductRepository productRepository;

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void submitApplication(Long userId, SupplierApplicationRequest request) {
        if (applicationRepository.existsByUserIdAndStatus(userId, "PENDING")) {
            throw new BusinessException(ErrorCode.SUPPLIER_APPLICATION_EXISTS);
        }
        @lombok.NonNull SupplierApplication app = SupplierApplication.builder()
                .userId(userId).companyName(request.getCompanyName())
                .contactPerson(request.getContactPerson())
                .contactPhone(request.getContactPhone())
                .businessLicense(request.getBusinessLicense())
                .address(request.getAddress()).description(request.getDescription())
                .status("PENDING").build();
        applicationRepository.save(app);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void auditApplication(Long applicationId, String action, String rejectReason, Long auditorId) {
        SupplierApplication app = applicationRepository.findById(applicationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SUPPLIER_NOT_FOUND));
        if (!"PENDING".equals(app.getStatus())) {
            throw new BusinessException("Already processed");
        }
        app.setAuditorId(auditorId);
        app.setAuditTime(LocalDateTime.now());
        if ("APPROVE".equalsIgnoreCase(action)) {
            app.setStatus("APPROVED");
            @lombok.NonNull Supplier supplier = Supplier.builder()
                    .userId(app.getUserId()).companyName(app.getCompanyName())
                    .contactPerson(app.getContactPerson()).contactPhone(app.getContactPhone())
                    .businessLicense(app.getBusinessLicense()).address(app.getAddress())
                    .description(app.getDescription()).status("APPROVED").build();
            supplierRepository.save(supplier);
        } else {
            app.setStatus("REJECTED");
            app.setRejectReason(rejectReason);
        }
        applicationRepository.save(app);
    }

    @Override
    public PageResult<SupplierResponse> listSuppliers(String keyword, String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Supplier> suppliers = supplierRepository.search(keyword, status, pr);
        return PageResult.of(
                suppliers.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                suppliers.getTotalElements(), page, size);
    }

    @Override
    @SuppressWarnings("null")
    public SupplierResponse getSupplierByUserId(@lombok.NonNull Long userId) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SUPPLIER_NOT_FOUND));
        return toResponse(supplier);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public SupplierResponse updateSupplier(Long userId, SupplierApplicationRequest request) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SUPPLIER_NOT_FOUND));
        if (request.getCompanyName() != null) supplier.setCompanyName(request.getCompanyName());
        if (request.getContactPerson() != null) supplier.setContactPerson(request.getContactPerson());
        if (request.getContactPhone() != null) supplier.setContactPhone(request.getContactPhone());
        if (request.getAddress() != null) supplier.setAddress(request.getAddress());
        if (request.getDescription() != null) supplier.setDescription(request.getDescription());
        return toResponse(supplierRepository.save(supplier));
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ProductResponse addProduct(Long supplierId, ProductRequest request) {
        @lombok.NonNull SupplierProduct product = SupplierProduct.builder()
                .supplierId(supplierId).productName(request.getProductName())
                .category(request.getCategory()).description(request.getDescription())
                .price(request.getPrice()).unit(request.getUnit())
                .minOrderQty(request.getMinOrderQty()).imageUrl(request.getImageUrl())
                .status("ACTIVE").build();
        return toProductResponse(productRepository.save(product));
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public ProductResponse updateProduct(Long productId, ProductRequest request) {
        SupplierProduct product = productRepository.findById(productId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND));
        if (request.getProductName() != null) product.setProductName(request.getProductName());
        if (request.getCategory() != null) product.setCategory(request.getCategory());
        if (request.getDescription() != null) product.setDescription(request.getDescription());
        if (request.getPrice() != null) product.setPrice(request.getPrice());
        if (request.getUnit() != null) product.setUnit(request.getUnit());
        if (request.getMinOrderQty() != null) product.setMinOrderQty(request.getMinOrderQty());
        if (request.getImageUrl() != null) product.setImageUrl(request.getImageUrl());
        return toProductResponse(productRepository.save(product));
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void deleteProduct(@lombok.NonNull Long productId) {
        productRepository.deleteById(productId);
    }

    @Override
    public PageResult<ProductResponse> listProducts(Long supplierId, String keyword, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<SupplierProduct> products = productRepository.search(supplierId, keyword, pr);
        return PageResult.of(
                products.getContent().stream().map(this::toProductResponse).collect(Collectors.toList()),
                products.getTotalElements(), page, size);
    }

    private SupplierResponse toResponse(Supplier s) {
        SupplierResponse resp = SupplierResponse.builder()
                .id(s.getId()).userId(s.getUserId())
                .companyName(s.getCompanyName()).contactPerson(s.getContactPerson())
                .contactPhone(s.getContactPhone()).businessLicense(s.getBusinessLicense())
                .address(s.getAddress()).description(s.getDescription())
                .status(s.getStatus()).createdAt(s.getCreatedAt()).updatedAt(s.getUpdatedAt())
                .build();
        // 关联 User 信息
        if (s.getUserId() != null) {
            userRepository.findById(s.getUserId()).ifPresent(user -> {
                resp.setUsername(user.getUsername());
                resp.setEmail(user.getEmail());
                resp.setPhone(user.getPhone());
            });
        }
        return resp;
    }

    private ProductResponse toProductResponse(SupplierProduct p) {
        return ProductResponse.builder()
                .id(p.getId()).supplierId(p.getSupplierId())
                .productName(p.getProductName()).category(p.getCategory())
                .description(p.getDescription()).price(p.getPrice())
                .unit(p.getUnit()).minOrderQty(p.getMinOrderQty())
                .imageUrl(p.getImageUrl()).status(p.getStatus()).createdAt(p.getCreatedAt())
                .build();
    }
}
