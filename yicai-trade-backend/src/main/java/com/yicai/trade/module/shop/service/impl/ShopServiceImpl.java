package com.yicai.trade.module.shop.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.shop.dto.*;
import com.yicai.trade.module.shop.entity.Shop;
import com.yicai.trade.module.shop.entity.ShopStatsDaily;
import com.yicai.trade.module.shop.repository.ShopRepository;
import com.yicai.trade.module.shop.repository.ShopStatsDailyRepository;
import com.yicai.trade.module.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShopServiceImpl implements ShopService {

    private final ShopRepository shopRepository;
    private final ShopStatsDailyRepository shopStatsDailyRepository;

    @Override
    @Transactional
    public ShopResponse create(ShopCreateRequest req) {
        shopRepository.findBySupplierId(req.getSupplierId()).ifPresent(s -> {
            throw new RuntimeException("该供应商已有店铺");
        });
        Shop shop = Shop.builder()
                .supplierId(req.getSupplierId())
                .shopName(req.getShopName())
                .shopLogo(req.getShopLogo())
                .shopBanner(req.getShopBanner())
                .shopDescription(req.getShopDescription())
                .mainProducts(req.getMainProducts())
                .industry(req.getIndustry())
                .province(req.getProvince())
                .city(req.getCity())
                .detailAddress(req.getDetailAddress())
                .contactName(req.getContactName())
                .contactPhone(req.getContactPhone())
                .contactEmail(req.getContactEmail())
                .status("ACTIVE")
                .build();
        return toResponse(shopRepository.save(shop));
    }

    @Override
    public ShopResponse getBySupplierId(Long supplierId) {
        return shopRepository.findBySupplierId(supplierId).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("店铺不存在，供应商ID: " + supplierId));
    }

    @Override
    public ShopResponse getById(Long id) {
        return shopRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("店铺不存在: " + id));
    }

    @Override
    @Transactional
    public ShopResponse updateInfo(Long supplierId, ShopCreateRequest req) {
        Shop shop = shopRepository.findBySupplierId(supplierId)
                .orElseThrow(() -> new RuntimeException("店铺不存在"));
        shop.setShopName(req.getShopName());
        shop.setShopLogo(req.getShopLogo());
        shop.setShopBanner(req.getShopBanner());
        shop.setShopDescription(req.getShopDescription());
        shop.setMainProducts(req.getMainProducts());
        shop.setIndustry(req.getIndustry());
        shop.setProvince(req.getProvince());
        shop.setCity(req.getCity());
        shop.setDetailAddress(req.getDetailAddress());
        shop.setContactName(req.getContactName());
        shop.setContactPhone(req.getContactPhone());
        shop.setContactEmail(req.getContactEmail());
        return toResponse(shopRepository.save(shop));
    }

    @Override
    @Transactional
    public ShopResponse updateDecoration(Long supplierId, ShopDecorationRequest req) {
        Shop shop = shopRepository.findBySupplierId(supplierId)
                .orElseThrow(() -> new RuntimeException("店铺不存在"));
        if (req.getShopBanner() != null) shop.setShopBanner(req.getShopBanner());
        if (req.getThemeColor() != null) shop.setThemeColor(req.getThemeColor());
        if (req.getCustomCss() != null) shop.setCustomCss(req.getCustomCss());
        if (req.getSectionsConfig() != null) shop.setSectionsConfig(req.getSectionsConfig());
        if (req.getSeoTitle() != null) shop.setSeoTitle(req.getSeoTitle());
        if (req.getSeoKeywords() != null) shop.setSeoKeywords(req.getSeoKeywords());
        if (req.getSeoDescription() != null) shop.setSeoDescription(req.getSeoDescription());
        return toResponse(shopRepository.save(shop));
    }

    @Override
    @Transactional
    public void incrementVisit(Long shopId) {
        shopRepository.findById(shopId).ifPresent(shop -> {
            shop.setVisitCount(shop.getVisitCount() + 1);
            shopRepository.save(shop);
        });
    }

    @Override
    public PageResult<ShopResponse> list(String status, String industry, String keyword, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "visitCount"));
        Page<Shop> p;
        if (keyword != null && !keyword.isEmpty()) {
            p = shopRepository.findByShopNameContaining(keyword, pageable);
        } else if (industry != null && !industry.isEmpty()) {
            p = shopRepository.findByIndustry(industry, pageable);
        } else if (status != null && !status.isEmpty()) {
            p = shopRepository.findByStatus(status, pageable);
        } else {
            p = shopRepository.findAll(pageable);
        }
        List<ShopResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    public ShopDashboardResponse getDashboard(Long supplierId, LocalDate startDate, LocalDate endDate) {
        Shop shop = shopRepository.findBySupplierId(supplierId)
                .orElseThrow(() -> new RuntimeException("店铺不存在"));

        ShopDashboardResponse resp = new ShopDashboardResponse();
        resp.setTotalPageViews(shopStatsDailyRepository.sumPageViews(shop.getId(), startDate, endDate));
        resp.setTotalOrders(shopStatsDailyRepository.sumOrderCount(shop.getId(), startDate, endDate));
        BigDecimal totalAmount = shopStatsDailyRepository.sumOrderAmount(shop.getId(), startDate, endDate);
        resp.setTotalOrderAmount(totalAmount != null ? totalAmount : BigDecimal.ZERO);

        List<ShopStatsDaily> dailyStats = shopStatsDailyRepository
                .findByShopIdAndStatDateBetweenOrderByStatDateAsc(shop.getId(), startDate, endDate);
        resp.setDailyStats(dailyStats.stream().map(ds -> {
            ShopDashboardResponse.DailyStat stat = new ShopDashboardResponse.DailyStat();
            stat.setDate(ds.getStatDate().toString());
            stat.setPageViews(ds.getPageViews());
            stat.setUniqueVisitors(ds.getUniqueVisitors());
            stat.setInquiryCount(ds.getInquiryCount());
            stat.setOrderCount(ds.getOrderCount());
            stat.setOrderAmount(ds.getOrderAmount());
            return stat;
        }).collect(Collectors.toList()));

        long totalInquiries = dailyStats.stream().mapToLong(ShopStatsDaily::getInquiryCount).sum();
        resp.setTotalInquiries(totalInquiries);
        return resp;
    }

    private ShopResponse toResponse(Shop s) {
        ShopResponse r = new ShopResponse();
        r.setId(s.getId());
        r.setSupplierId(s.getSupplierId());
        r.setShopName(s.getShopName());
        r.setShopLogo(s.getShopLogo());
        r.setShopBanner(s.getShopBanner());
        r.setShopDescription(s.getShopDescription());
        r.setMainProducts(s.getMainProducts());
        r.setIndustry(s.getIndustry());
        r.setProvince(s.getProvince());
        r.setCity(s.getCity());
        r.setDetailAddress(s.getDetailAddress());
        r.setContactName(s.getContactName());
        r.setContactPhone(s.getContactPhone());
        r.setContactEmail(s.getContactEmail());
        r.setThemeColor(s.getThemeColor());
        r.setCustomCss(s.getCustomCss());
        r.setSectionsConfig(s.getSectionsConfig());
        r.setSeoTitle(s.getSeoTitle());
        r.setSeoKeywords(s.getSeoKeywords());
        r.setSeoDescription(s.getSeoDescription());
        r.setVisitCount(s.getVisitCount());
        r.setProductCount(s.getProductCount());
        r.setStatus(s.getStatus());
        r.setCreatedAt(s.getCreatedAt());
        r.setUpdatedAt(s.getUpdatedAt());
        return r;
    }
}
