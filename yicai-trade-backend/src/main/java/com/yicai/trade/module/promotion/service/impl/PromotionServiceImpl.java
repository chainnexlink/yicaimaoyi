package com.yicai.trade.module.promotion.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.promotion.dto.*;
import com.yicai.trade.module.promotion.entity.*;
import com.yicai.trade.module.promotion.repository.*;
import com.yicai.trade.module.promotion.service.PromotionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PromotionServiceImpl implements PromotionService {

    private final PromotionRepository promotionRepository;
    private final PlatformEventRepository platformEventRepository;
    private final EventSignupRepository eventSignupRepository;

    @Override
    @Transactional
    public PromotionResponse createPromotion(PromotionCreateRequest req) {
        Promotion p = Promotion.builder()
                .supplierId(req.getSupplierId())
                .title(req.getTitle())
                .promoType(req.getPromoType())
                .targetType(req.getTargetType())
                .targetId(req.getTargetId())
                .keywords(req.getKeywords())
                .bidAmount(req.getBidAmount())
                .dailyBudget(req.getDailyBudget())
                .totalBudget(req.getTotalBudget())
                .startTime(req.getStartTime())
                .endTime(req.getEndTime())
                .status("DRAFT")
                .build();
        return toPromoResponse(promotionRepository.save(p));
    }

    @Override
    public PromotionResponse getById(Long id) {
        return promotionRepository.findById(id).map(this::toPromoResponse)
                .orElseThrow(() -> new RuntimeException("推广不存在: " + id));
    }

    @Override
    public PageResult<PromotionResponse> list(Long supplierId, String status, String promoType, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Promotion> p;
        if (supplierId != null && status != null && !status.isEmpty()) {
            p = promotionRepository.findBySupplierIdAndStatus(supplierId, status, pageable);
        } else if (supplierId != null) {
            p = promotionRepository.findBySupplierId(supplierId, pageable);
        } else if (status != null && !status.isEmpty()) {
            p = promotionRepository.findByStatus(status, pageable);
        } else if (promoType != null && !promoType.isEmpty()) {
            p = promotionRepository.findByPromoType(promoType, pageable);
        } else {
            p = promotionRepository.findAll(pageable);
        }
        List<PromotionResponse> list = p.getContent().stream().map(this::toPromoResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void submitForReview(Long id) {
        Promotion p = getPromotion(id);
        p.setStatus("PENDING_REVIEW");
        promotionRepository.save(p);
    }

    @Override
    @Transactional
    public void approve(Long id) {
        Promotion p = getPromotion(id);
        p.setStatus("ACTIVE");
        promotionRepository.save(p);
    }

    @Override
    @Transactional
    public void reject(Long id, String reason) {
        Promotion p = getPromotion(id);
        p.setStatus("REJECTED");
        p.setRejectReason(reason);
        promotionRepository.save(p);
    }

    @Override
    @Transactional
    public void pause(Long id) {
        Promotion p = getPromotion(id);
        p.setStatus("PAUSED");
        promotionRepository.save(p);
    }

    @Override
    @Transactional
    public void resume(Long id) {
        Promotion p = getPromotion(id);
        p.setStatus("ACTIVE");
        promotionRepository.save(p);
    }

    @Override
    @Transactional
    public void recordImpression(Long id) {
        promotionRepository.findById(id).ifPresent(p -> {
            p.setImpressions(p.getImpressions() + 1);
            promotionRepository.save(p);
        });
    }

    @Override
    @Transactional
    public void recordClick(Long id) {
        promotionRepository.findById(id).ifPresent(p -> {
            p.setClicks(p.getClicks() + 1);
            promotionRepository.save(p);
        });
    }

    @Override
    @Transactional
    public void recordConversion(Long id) {
        promotionRepository.findById(id).ifPresent(p -> {
            p.setConversions(p.getConversions() + 1);
            promotionRepository.save(p);
        });
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", promotionRepository.count());
        stats.put("active", promotionRepository.countByStatus("ACTIVE"));
        stats.put("pendingReview", promotionRepository.countByStatus("PENDING_REVIEW"));
        stats.put("paused", promotionRepository.countByStatus("PAUSED"));
        return stats;
    }

    // === Platform Events ===

    @Override
    @Transactional
    public PlatformEventResponse createEvent(String eventName, String eventType, String description,
                                              String bannerUrl, String rules, Integer maxParticipants) {
        PlatformEvent event = PlatformEvent.builder()
                .eventName(eventName)
                .eventType(eventType)
                .description(description)
                .bannerUrl(bannerUrl)
                .rules(rules)
                .maxParticipants(maxParticipants)
                .status("DRAFT")
                .build();
        return toEventResponse(platformEventRepository.save(event));
    }

    @Override
    public PageResult<PlatformEventResponse> listEvents(String status, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<PlatformEvent> p;
        if (status != null && !status.isEmpty()) {
            p = platformEventRepository.findByStatus(status, pageable);
        } else {
            p = platformEventRepository.findAll(pageable);
        }
        List<PlatformEventResponse> list = p.getContent().stream().map(this::toEventResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void openSignup(Long eventId) {
        PlatformEvent event = platformEventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("活动不存在: " + eventId));
        event.setStatus("SIGNUP_OPEN");
        platformEventRepository.save(event);
    }

    @Override
    @Transactional
    public void signup(Long eventId, Long supplierId, String productIds, String note) {
        if (eventSignupRepository.existsByEventIdAndSupplierId(eventId, supplierId)) {
            throw new RuntimeException("已报名该活动");
        }
        PlatformEvent event = platformEventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
        if (!"SIGNUP_OPEN".equals(event.getStatus())) {
            throw new RuntimeException("活动当前不接受报名");
        }
        if (event.getMaxParticipants() != null && event.getCurrentParticipants() >= event.getMaxParticipants()) {
            throw new RuntimeException("活动报名人数已满");
        }
        EventSignup signup = EventSignup.builder()
                .eventId(eventId)
                .supplierId(supplierId)
                .productIds(productIds)
                .applicationNote(note)
                .status("PENDING")
                .build();
        eventSignupRepository.save(signup);
    }

    @Override
    @Transactional
    public void approveSignup(Long signupId) {
        EventSignup signup = eventSignupRepository.findById(signupId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));
        signup.setStatus("APPROVED");
        eventSignupRepository.save(signup);
        platformEventRepository.findById(signup.getEventId()).ifPresent(event -> {
            event.setCurrentParticipants(event.getCurrentParticipants() + 1);
            platformEventRepository.save(event);
        });
    }

    @Override
    @Transactional
    public void rejectSignup(Long signupId, String reason) {
        EventSignup signup = eventSignupRepository.findById(signupId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));
        signup.setStatus("REJECTED");
        signup.setRejectReason(reason);
        eventSignupRepository.save(signup);
    }

    private Promotion getPromotion(Long id) {
        return promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("推广不存在: " + id));
    }

    private PromotionResponse toPromoResponse(Promotion p) {
        PromotionResponse r = new PromotionResponse();
        r.setId(p.getId());
        r.setSupplierId(p.getSupplierId());
        r.setTitle(p.getTitle());
        r.setPromoType(p.getPromoType());
        r.setTargetType(p.getTargetType());
        r.setTargetId(p.getTargetId());
        r.setKeywords(p.getKeywords());
        r.setBidAmount(p.getBidAmount());
        r.setDailyBudget(p.getDailyBudget());
        r.setTotalBudget(p.getTotalBudget());
        r.setSpentAmount(p.getSpentAmount());
        r.setImpressions(p.getImpressions());
        r.setClicks(p.getClicks());
        r.setConversions(p.getConversions());
        r.setStartTime(p.getStartTime());
        r.setEndTime(p.getEndTime());
        r.setStatus(p.getStatus());
        r.setRejectReason(p.getRejectReason());
        r.setCreatedAt(p.getCreatedAt());
        return r;
    }

    private PlatformEventResponse toEventResponse(PlatformEvent e) {
        PlatformEventResponse r = new PlatformEventResponse();
        r.setId(e.getId());
        r.setEventName(e.getEventName());
        r.setEventType(e.getEventType());
        r.setDescription(e.getDescription());
        r.setBannerUrl(e.getBannerUrl());
        r.setRules(e.getRules());
        r.setMaxParticipants(e.getMaxParticipants());
        r.setCurrentParticipants(e.getCurrentParticipants());
        r.setSignupStart(e.getSignupStart());
        r.setSignupEnd(e.getSignupEnd());
        r.setEventStart(e.getEventStart());
        r.setEventEnd(e.getEventEnd());
        r.setStatus(e.getStatus());
        r.setCreatedAt(e.getCreatedAt());
        return r;
    }
}
