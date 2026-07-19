package com.yicai.trade.module.inquiry.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.inquiry.dto.InquiryResponse;
import com.yicai.trade.module.inquiry.dto.QuotationResponse;
import com.yicai.trade.module.inquiry.entity.Inquiry;
import com.yicai.trade.module.inquiry.entity.Quotation;
import com.yicai.trade.module.inquiry.repository.InquiryRepository;
import com.yicai.trade.module.inquiry.repository.QuotationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/inquiries")
@RequiredArgsConstructor
@Tag(name = "InquiryAdmin", description = "询价管理后台")
public class InquiryAdminController {

    private final InquiryRepository inquiryRepository;
    private final QuotationRepository quotationRepository;

    // ===== L2: 询价列表（多维筛选） =====

    @GetMapping
    @Operation(summary = "管理端-询价分页列表(多维筛选)")
    public Result<PageResult<InquiryResponse>> listInquiries(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        PageRequest pageable = PageRequest.of(page, size, sort);

        // 空字符串转null
        if (status != null && status.isBlank()) status = null;
        if (category != null && category.isBlank()) category = null;
        if (keyword != null && keyword.isBlank()) keyword = null;

        Page<Inquiry> pageData = inquiryRepository.findByAdminFilters(status, category, keyword, startTime, endTime, pageable);

        // 批量查询每个询价的报价数
        Map<Long, Long> quoteCounts = new HashMap<>();
        quotationRepository.countGroupByInquiryId().forEach(row -> {
            quoteCounts.put((Long) row[0], (Long) row[1]);
        });

        List<InquiryResponse> list = pageData.getContent().stream().map(i -> {
            List<Quotation> quotes = quotationRepository.findByInquiryId(i.getId());
            return toResponse(i, quotes, quoteCounts.getOrDefault(i.getId(), 0L));
        }).collect(Collectors.toList());

        return Result.success(PageResult.of(list, pageData.getTotalElements(), page, size));
    }

    // ===== L2: 统计汇总 =====

    @GetMapping("/stats")
    @Operation(summary = "询价统计汇总")
    public Result<Map<String, Object>> getStats() {
        Map<String, Object> stats = new LinkedHashMap<>();

        long total = inquiryRepository.count();
        stats.put("total", total);

        Map<String, Long> statusMap = new LinkedHashMap<>();
        inquiryRepository.countGroupByStatus().forEach(row -> {
            statusMap.put((String) row[0], (Long) row[1]);
        });
        stats.put("statusCounts", statusMap);
        stats.put("open", statusMap.getOrDefault("OPEN", 0L));
        stats.put("closed", statusMap.getOrDefault("CLOSED", 0L));

        // 报价统计
        long totalQuotations = quotationRepository.count();
        stats.put("totalQuotations", totalQuotations);

        // 品类排行
        List<Map<String, Object>> categoryRank = new ArrayList<>();
        inquiryRepository.countByCategory().forEach(row -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("category", row[0]);
            m.put("count", row[1]);
            categoryRank.add(m);
        });
        stats.put("categoryRank", categoryRank);

        return Result.success(stats);
    }

    // ===== L2: 品类列表(用于筛选下拉) =====

    @GetMapping("/categories")
    @Operation(summary = "获取所有品类(筛选用)")
    public Result<List<String>> getCategories() {
        return Result.success(inquiryRepository.findDistinctCategories());
    }

    // ===== L3: 询价详情 =====

    @GetMapping("/{id}")
    @Operation(summary = "询价详情(含报价列表)")
    public Result<Map<String, Object>> getInquiryDetail(@PathVariable Long id) {
        Inquiry inquiry = inquiryRepository.findById(id).orElse(null);
        if (inquiry == null) return Result.notFound("询价不存在");

        Map<String, Object> detail = new LinkedHashMap<>();
        detail.put("inquiry", toBasicResponse(inquiry));

        // 报价列表
        List<Quotation> quotes = quotationRepository.findByInquiryId(id);
        detail.put("quotations", quotes.stream().map(this::toQuotationResp).collect(Collectors.toList()));
        detail.put("quotationCount", quotes.size());

        // 报价统计
        if (!quotes.isEmpty()) {
            Map<String, Object> quoteStat = new LinkedHashMap<>();
            var prices = quotes.stream()
                    .filter(q -> q.getTotalPrice() != null)
                    .map(q -> q.getTotalPrice().doubleValue())
                    .collect(Collectors.toList());
            if (!prices.isEmpty()) {
                quoteStat.put("minPrice", Collections.min(prices));
                quoteStat.put("maxPrice", Collections.max(prices));
                quoteStat.put("avgPrice", prices.stream().mapToDouble(d -> d).average().orElse(0));
            }
            var days = quotes.stream()
                    .filter(q -> q.getDeliveryDays() != null)
                    .map(Quotation::getDeliveryDays)
                    .collect(Collectors.toList());
            if (!days.isEmpty()) {
                quoteStat.put("minDeliveryDays", Collections.min(days));
                quoteStat.put("maxDeliveryDays", Collections.max(days));
            }
            long accepted = quotes.stream().filter(q -> "ACCEPTED".equals(q.getStatus())).count();
            long rejected = quotes.stream().filter(q -> "REJECTED".equals(q.getStatus())).count();
            long submitted = quotes.stream().filter(q -> "SUBMITTED".equals(q.getStatus())).count();
            quoteStat.put("accepted", accepted);
            quoteStat.put("rejected", rejected);
            quoteStat.put("submitted", submitted);
            detail.put("quoteStats", quoteStat);
        }

        return Result.success(detail);
    }

    // ===== L3: 询价的报价列表 =====

    @GetMapping("/{id}/quotations")
    @Operation(summary = "某询价下所有报价(含排序)")
    public Result<List<QuotationResponse>> getInquiryQuotations(
            @PathVariable Long id,
            @RequestParam(defaultValue = "totalPrice") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {
        List<Quotation> quotes = quotationRepository.findByInquiryId(id);

        // 排序
        Comparator<Quotation> comp;
        switch (sortBy) {
            case "unitPrice":
                comp = Comparator.comparing(q -> q.getUnitPrice() != null ? q.getUnitPrice().doubleValue() : Double.MAX_VALUE);
                break;
            case "deliveryDays":
                comp = Comparator.comparing(q -> q.getDeliveryDays() != null ? q.getDeliveryDays() : Integer.MAX_VALUE);
                break;
            case "createdAt":
                comp = Comparator.comparing(q -> q.getCreatedAt() != null ? q.getCreatedAt() : LocalDateTime.MIN);
                break;
            default: // totalPrice
                comp = Comparator.comparing(q -> q.getTotalPrice() != null ? q.getTotalPrice().doubleValue() : Double.MAX_VALUE);
                break;
        }
        if ("desc".equalsIgnoreCase(sortDir)) comp = comp.reversed();
        quotes.sort(comp);

        return Result.success(quotes.stream().map(this::toQuotationResp).collect(Collectors.toList()));
    }

    // ===== L4: 单个报价详情 =====

    @GetMapping("/quotations/{quotationId}")
    @Operation(summary = "报价详情")
    public Result<Map<String, Object>> getQuotationDetail(@PathVariable Long quotationId) {
        Quotation q = quotationRepository.findById(quotationId).orElse(null);
        if (q == null) return Result.notFound("报价不存在");

        Map<String, Object> detail = new LinkedHashMap<>();
        detail.put("quotation", toQuotationResp(q));

        // 关联的询价信息
        Inquiry inquiry = inquiryRepository.findById(q.getInquiryId()).orElse(null);
        if (inquiry != null) {
            detail.put("inquiry", toBasicResponse(inquiry));
        }

        // 同询价下其他报价(用于横向比较)
        List<Quotation> siblings = quotationRepository.findByInquiryId(q.getInquiryId());
        detail.put("siblingQuotations", siblings.stream()
                .filter(s -> !s.getId().equals(quotationId))
                .map(this::toQuotationResp)
                .collect(Collectors.toList()));

        // 价格排名
        List<Quotation> sorted = siblings.stream()
                .filter(s -> s.getTotalPrice() != null)
                .sorted(Comparator.comparing(Quotation::getTotalPrice))
                .collect(Collectors.toList());
        int rank = 1;
        for (Quotation s : sorted) {
            if (s.getId().equals(quotationId)) break;
            rank++;
        }
        detail.put("priceRank", rank);
        detail.put("totalQuotations", siblings.size());

        return Result.success(detail);
    }

    // ===== 管理操作 =====

    @PostMapping("/{id}/close")
    @Operation(summary = "管理员关闭询价")
    public Result<Void> closeInquiry(@PathVariable Long id) {
        Inquiry inquiry = inquiryRepository.findById(id).orElse(null);
        if (inquiry == null) return Result.notFound("询价不存在");
        if ("CLOSED".equals(inquiry.getStatus())) return Result.badRequest("询价已关闭");
        inquiry.setStatus("CLOSED");
        inquiryRepository.save(inquiry);
        return Result.success();
    }

    @PostMapping("/quotations/{quotationId}/accept")
    @Operation(summary = "管理员接受报价")
    public Result<Void> acceptQuotation(@PathVariable Long quotationId) {
        Quotation q = quotationRepository.findById(quotationId).orElse(null);
        if (q == null) return Result.notFound("报价不存在");

        q.setStatus("ACCEPTED");
        quotationRepository.save(q);

        // 同询价下其他SUBMITTED报价自动REJECTED
        List<Quotation> others = quotationRepository.findByInquiryId(q.getInquiryId());
        for (Quotation o : others) {
            if (!o.getId().equals(quotationId) && "SUBMITTED".equals(o.getStatus())) {
                o.setStatus("REJECTED");
                quotationRepository.save(o);
            }
        }
        // 关闭询价
        inquiryRepository.findById(q.getInquiryId()).ifPresent(i -> {
            i.setStatus("CLOSED");
            inquiryRepository.save(i);
        });

        return Result.success();
    }

    // ===== 工具方法 =====

    private InquiryResponse toResponse(Inquiry i, List<Quotation> quotes, Long quoteCount) {
        return InquiryResponse.builder()
                .id(i.getId())
                .buyerId(i.getBuyerId())
                .title(i.getTitle())
                .description(i.getDescription())
                .productCategory(i.getProductCategory())
                .expectedQuantity(i.getExpectedQuantity())
                .unit(i.getUnit())
                .status(i.getStatus())
                .deadline(i.getDeadline())
                .quotations(quotes != null ? quotes.stream().map(this::toQuotationResp).collect(Collectors.toList()) : null)
                .createdAt(i.getCreatedAt())
                .build();
    }

    private InquiryResponse toBasicResponse(Inquiry i) {
        return InquiryResponse.builder()
                .id(i.getId())
                .buyerId(i.getBuyerId())
                .title(i.getTitle())
                .description(i.getDescription())
                .productCategory(i.getProductCategory())
                .expectedQuantity(i.getExpectedQuantity())
                .unit(i.getUnit())
                .status(i.getStatus())
                .deadline(i.getDeadline())
                .createdAt(i.getCreatedAt())
                .build();
    }

    private QuotationResponse toQuotationResp(Quotation q) {
        return QuotationResponse.builder()
                .id(q.getId())
                .inquiryId(q.getInquiryId())
                .supplierId(q.getSupplierId())
                .unitPrice(q.getUnitPrice())
                .totalPrice(q.getTotalPrice())
                .deliveryDays(q.getDeliveryDays())
                .description(q.getDescription())
                .status(q.getStatus())
                .createdAt(q.getCreatedAt())
                .build();
    }
}
