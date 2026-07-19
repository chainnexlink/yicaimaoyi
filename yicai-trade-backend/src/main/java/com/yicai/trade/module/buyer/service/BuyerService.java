package com.yicai.trade.module.buyer.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.buyer.dto.BuyerProfileRequest;
import com.yicai.trade.module.buyer.dto.BuyerResponse;
import com.yicai.trade.module.buyer.entity.BuyerFavorite;
import lombok.NonNull;

public interface BuyerService {
    BuyerResponse getOrCreateBuyer(@NonNull Long userId);
    BuyerResponse updateProfile(@NonNull Long userId, BuyerProfileRequest request);
    void addFavorite(@NonNull Long buyerId, @NonNull Long productId, Long supplierId, String type);
    void removeFavorite(@NonNull Long buyerId, @NonNull Long productId);
    PageResult<BuyerFavorite> listFavorites(@NonNull Long buyerId, int page, int size);
    boolean isFavorite(@NonNull Long buyerId, @NonNull Long productId);
}
