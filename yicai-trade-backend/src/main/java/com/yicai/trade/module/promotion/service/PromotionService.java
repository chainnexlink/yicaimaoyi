package com.yicai.trade.module.promotion.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.promotion.dto.*;

import java.util.Map;

public interface PromotionService {
    PromotionResponse createPromotion(PromotionCreateRequest request);
    PromotionResponse getById(Long id);
    PageResult<PromotionResponse> list(Long supplierId, String status, String promoType, int page, int size);
    void submitForReview(Long id);
    void approve(Long id);
    void reject(Long id, String reason);
    void pause(Long id);
    void resume(Long id);
    void recordImpression(Long id);
    void recordClick(Long id);
    void recordConversion(Long id);
    Map<String, Long> getStats();

    // Platform Events
    PlatformEventResponse createEvent(String eventName, String eventType, String description,
                                       String bannerUrl, String rules, Integer maxParticipants);
    PageResult<PlatformEventResponse> listEvents(String status, int page, int size);
    void openSignup(Long eventId);
    void signup(Long eventId, Long supplierId, String productIds, String note);
    void approveSignup(Long signupId);
    void rejectSignup(Long signupId, String reason);
}
