package com.yicai.trade.module.supplier.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.supplier.dto.*;

public interface SupplierService {
    void submitApplication(Long userId, SupplierApplicationRequest request);
    void auditApplication(Long applicationId, String action, String rejectReason, Long auditorId);
    PageResult<SupplierResponse> listSuppliers(String keyword, String status, int page, int size);
    SupplierResponse getSupplierByUserId(Long userId);
    SupplierResponse updateSupplier(Long userId, SupplierApplicationRequest request);
    ProductResponse addProduct(Long supplierId, ProductRequest request);
    ProductResponse updateProduct(Long productId, ProductRequest request);
    void deleteProduct(Long productId);
    PageResult<ProductResponse> listProducts(Long supplierId, String keyword, int page, int size);
}
