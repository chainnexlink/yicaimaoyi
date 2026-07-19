package com.yicai.trade.module.shop.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.shop.dto.*;

import java.time.LocalDate;

public interface ShopService {
    ShopResponse create(ShopCreateRequest request);
    ShopResponse getBySupplierId(Long supplierId);
    ShopResponse getById(Long id);
    ShopResponse updateInfo(Long supplierId, ShopCreateRequest request);
    ShopResponse updateDecoration(Long supplierId, ShopDecorationRequest request);
    void incrementVisit(Long shopId);
    PageResult<ShopResponse> list(String status, String industry, String keyword, int page, int size);
    ShopDashboardResponse getDashboard(Long supplierId, LocalDate startDate, LocalDate endDate);
}
