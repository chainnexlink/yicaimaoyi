package com.yicai.trade.module.buyer.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.buyer.dto.BuyerProfileRequest;
import com.yicai.trade.module.buyer.dto.BuyerResponse;
import com.yicai.trade.module.buyer.entity.Buyer;
import com.yicai.trade.module.buyer.entity.BuyerFavorite;
import com.yicai.trade.module.buyer.repository.BuyerFavoriteRepository;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.buyer.service.BuyerService;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BuyerServiceImpl implements BuyerService {

    private final BuyerRepository buyerRepository;
    private final BuyerFavoriteRepository favoriteRepository;

    @Override
    @Transactional
    @SuppressWarnings("null")
    public BuyerResponse getOrCreateBuyer(@NonNull Long userId) {
        Buyer buyer = buyerRepository.findByUserId(userId)
                .orElseGet(() -> buyerRepository.save(Buyer.builder().userId(userId).build()));
        return toResponse(buyer);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public BuyerResponse updateProfile(@NonNull Long userId, BuyerProfileRequest request) {
        Buyer buyer = buyerRepository.findByUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BUYER_NOT_FOUND));
        if (request.getCompanyName() != null) buyer.setCompanyName(request.getCompanyName());
        if (request.getContactPerson() != null) buyer.setContactPerson(request.getContactPerson());
        if (request.getContactPhone() != null) buyer.setContactPhone(request.getContactPhone());
        if (request.getAddress() != null) buyer.setAddress(request.getAddress());
        if (request.getIndustry() != null) buyer.setIndustry(request.getIndustry());
        if (request.getDescription() != null) buyer.setDescription(request.getDescription());
        return toResponse(buyerRepository.save(buyer));
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void addFavorite(@NonNull Long buyerId, @NonNull Long productId, Long supplierId, String type) {
        if (favoriteRepository.existsByBuyerIdAndProductId(buyerId, productId)) {
            return;
        }
        @NonNull BuyerFavorite fav = BuyerFavorite.builder()
                .buyerId(buyerId).productId(productId)
                .supplierId(supplierId).favoriteType(type).build();
        favoriteRepository.save(fav);
    }

    @Override
    @Transactional
    public void removeFavorite(@NonNull Long buyerId, @NonNull Long productId) {
        favoriteRepository.deleteByBuyerIdAndProductId(buyerId, productId);
    }

    @Override
    public PageResult<BuyerFavorite> listFavorites(@NonNull Long buyerId, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<BuyerFavorite> favorites = favoriteRepository.findByBuyerId(buyerId, pr);
        return PageResult.of(favorites.getContent(), favorites.getTotalElements(), page, size);
    }

    @Override
    public boolean isFavorite(@NonNull Long buyerId, @NonNull Long productId) {
        return favoriteRepository.existsByBuyerIdAndProductId(buyerId, productId);
    }

    private BuyerResponse toResponse(Buyer b) {
        return BuyerResponse.builder()
                .id(b.getId()).userId(b.getUserId())
                .companyName(b.getCompanyName()).contactPerson(b.getContactPerson())
                .contactPhone(b.getContactPhone()).address(b.getAddress())
                .industry(b.getIndustry()).description(b.getDescription())
                .createdAt(b.getCreatedAt()).updatedAt(b.getUpdatedAt())
                .build();
    }
}
