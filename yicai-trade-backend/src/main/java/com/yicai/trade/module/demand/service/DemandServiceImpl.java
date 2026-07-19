package com.yicai.trade.module.demand.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.demand.dto.*;
import com.yicai.trade.module.demand.entity.Demand;
import com.yicai.trade.module.demand.repository.DemandRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DemandServiceImpl implements DemandService {

    private final DemandRepository demandRepository;

    @Override
    @Transactional
    public DemandResponse createDemand(Long buyerId, DemandRequest request) {
        String demandNo = "DM" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
        Demand demand = Demand.builder()
                .demandNo(demandNo)
                .buyerId(buyerId)
                .buyerCompanyName("采购商")
                .title(request.getTitle())
                .description(request.getDescription())
                .categoryCode(request.getCategoryCode())
                .categoryName(request.getCategoryName())
                .quantity(request.getQuantity())
                .unit(request.getUnit())
                .budget(request.getBudget())
                .expectedDeliveryDays(request.getExpectedDeliveryDays())
                .status("PENDING")
                .auditStatus("PENDING")
                .expireTime(LocalDateTime.now().plusDays(30))
                .build();
        return toDemandResponse(demandRepository.save(demand));
    }

    @Override
    @Transactional
    public DemandResponse updateDemand(Long id, DemandRequest request) {
        Demand demand = demandRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
        demand.setTitle(request.getTitle());
        demand.setDescription(request.getDescription());
        demand.setCategoryCode(request.getCategoryCode());
        demand.setCategoryName(request.getCategoryName());
        demand.setQuantity(request.getQuantity());
        demand.setUnit(request.getUnit());
        demand.setBudget(request.getBudget());
        demand.setExpectedDeliveryDays(request.getExpectedDeliveryDays());
        return toDemandResponse(demandRepository.save(demand));
    }

    @Override
    @Transactional
    public void deleteDemand(Long id) {
        demandRepository.deleteById(id);
    }

    @Override
    public DemandResponse getDemand(Long id) {
        return demandRepository.findById(id)
                .map(this::toDemandResponse)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
    }

    @Override
    public DemandResponse getDemandByNo(String demandNo) {
        return demandRepository.findByDemandNo(demandNo)
                .map(this::toDemandResponse)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + demandNo));
    }

    @Override
    public PageResult<DemandResponse> listDemands(String status, String category, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Demand> demandPage;
        if (status != null && !status.isEmpty()) {
            demandPage = demandRepository.findByStatus(status, pageable);
        } else if (category != null && !category.isEmpty()) {
            demandPage = demandRepository.findByCategoryCode(category, pageable);
        } else {
            demandPage = demandRepository.findAll(pageable);
        }
        List<DemandResponse> content = demandPage.getContent().stream()
                .map(this::toDemandResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, demandPage.getTotalElements(), page, size);
    }

    @Override
    public PageResult<DemandResponse> listBuyerDemands(Long buyerId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Demand> demandPage = demandRepository.findByBuyerId(buyerId, pageable);
        List<DemandResponse> content = demandPage.getContent().stream()
                .map(this::toDemandResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, demandPage.getTotalElements(), page, size);
    }

    @Override
    public PageResult<DemandResponse> listPendingAudit(int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").ascending());
        Page<Demand> demandPage = demandRepository.findByAuditStatus("PENDING", pageable);
        List<DemandResponse> content = demandPage.getContent().stream()
                .map(this::toDemandResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, demandPage.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void approveDemand(Long id, Long auditorId) {
        Demand demand = demandRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
        demand.setAuditStatus("APPROVED");
        demand.setStatus("ACTIVE");
        demand.setAuditorId(auditorId);
        demand.setAuditTime(LocalDateTime.now());
        demandRepository.save(demand);
    }

    @Override
    @Transactional
    public void rejectDemand(Long id, Long auditorId, String reason) {
        Demand demand = demandRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
        demand.setAuditStatus("REJECTED");
        demand.setAuditRemark(reason);
        demand.setAuditorId(auditorId);
        demand.setAuditTime(LocalDateTime.now());
        demandRepository.save(demand);
    }

    @Override
    @Transactional
    public void closeDemand(Long id) {
        Demand demand = demandRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
        demand.setStatus("CLOSED");
        demandRepository.save(demand);
    }

    @Override
    @Transactional
    public void incrementResponseCount(Long id) {
        Demand demand = demandRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
        demand.setResponseCount(demand.getResponseCount() + 1);
        demandRepository.save(demand);
    }

    @Override
    @Transactional
    public void incrementViewCount(Long id) {
        Demand demand = demandRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("需求不存在: " + id));
        demand.setViewCount(demand.getViewCount() + 1);
        demandRepository.save(demand);
    }

    private DemandResponse toDemandResponse(Demand demand) {
        DemandResponse response = new DemandResponse();
        response.setId(demand.getId());
        response.setDemandNo(demand.getDemandNo());
        response.setBuyerId(demand.getBuyerId());
        response.setBuyerCompanyName(demand.getBuyerCompanyName());
        response.setTitle(demand.getTitle());
        response.setDescription(demand.getDescription());
        response.setCategoryCode(demand.getCategoryCode());
        response.setCategoryName(demand.getCategoryName());
        response.setQuantity(demand.getQuantity());
        response.setUnit(demand.getUnit());
        response.setBudget(demand.getBudget());
        response.setExpectedDeliveryDays(demand.getExpectedDeliveryDays());
        response.setResponseCount(demand.getResponseCount());
        response.setViewCount(demand.getViewCount());
        response.setStatus(demand.getStatus());
        response.setAuditStatus(demand.getAuditStatus());
        response.setAuditRemark(demand.getAuditRemark());
        response.setAuditTime(demand.getAuditTime());
        response.setExpireTime(demand.getExpireTime());
        response.setCreatedAt(demand.getCreatedAt());
        return response;
    }
}
