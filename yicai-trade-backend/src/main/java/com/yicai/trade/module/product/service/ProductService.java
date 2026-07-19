package com.yicai.trade.module.product.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.product.dto.*;
import java.util.Map;

public interface ProductService {
    ProductResponse createProduct(ProductRequest request);
    ProductResponse updateProduct(Long id, ProductRequest request);
    void deleteProduct(Long id);
    ProductResponse getProduct(Long id);
    PageResult<ProductResponse> listProducts(String auditStatus, String category, int page, int size);
    void auditProduct(Long id, String action, String remark);
    Map<String, Long> getProductStats();
}
