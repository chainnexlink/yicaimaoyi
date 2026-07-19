package com.yicai.trade.module.certification.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.certification.dto.FactoryAuditRequest;
import com.yicai.trade.module.certification.dto.FactoryAuditResponse;
import com.yicai.trade.module.certification.entity.FactoryAudit;
import com.yicai.trade.module.certification.repository.FactoryAuditRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FactoryAuditServiceImpl implements FactoryAuditService {

    private final FactoryAuditRepository factoryAuditRepository;

    @Override
    @Transactional
    public FactoryAuditResponse schedule(FactoryAuditRequest req) {
        FactoryAudit audit = FactoryAudit.builder()
                .auditNo("FA" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")))
                .supplierId(req.getSupplierId())
                .companyName(req.getCompanyName())
                .factoryAddress(req.getFactoryAddress())
                .auditType(req.getAuditType() != null ? req.getAuditType() : "INITIAL")
                .auditorName(req.getAuditorName())
                .auditorId(req.getAuditorId())
                .auditDate(req.getAuditDate())
                .productionCapacity(req.getProductionCapacity())
                .employeeCount(req.getEmployeeCount())
                .factoryArea(req.getFactoryArea())
                .equipmentList(req.getEquipmentList())
                .qualitySystem(req.getQualitySystem())
                .status("SCHEDULED")
                .build();
        return toResponse(factoryAuditRepository.save(audit));
    }

    @Override
    public FactoryAuditResponse getById(Long id) {
        return factoryAuditRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("验厂记录不存在: " + id));
    }

    @Override
    public PageResult<FactoryAuditResponse> list(String status, Long supplierId, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<FactoryAudit> p;
        if (supplierId != null) {
            p = factoryAuditRepository.findBySupplierId(supplierId, pageable);
        } else if (status != null && !status.isEmpty()) {
            p = factoryAuditRepository.findByStatus(status, pageable);
        } else {
            p = factoryAuditRepository.findAll(pageable);
        }
        List<FactoryAuditResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void startAudit(Long id) {
        FactoryAudit audit = getAudit(id);
        audit.setStatus("IN_PROGRESS");
        factoryAuditRepository.save(audit);
    }

    @Override
    @Transactional
    public void submitResult(Long id, String auditItems, String photos, Integer overallScore, String conclusion) {
        FactoryAudit audit = getAudit(id);
        audit.setAuditItems(auditItems);
        audit.setPhotos(photos);
        audit.setOverallScore(overallScore);
        audit.setConclusion(conclusion);
        audit.setStatus("COMPLETED");
        factoryAuditRepository.save(audit);
    }

    @Override
    @Transactional
    public void pass(Long id) {
        FactoryAudit audit = getAudit(id);
        audit.setStatus("PASSED");
        audit.setNextAuditDate(LocalDate.now().plusYears(1));
        factoryAuditRepository.save(audit);
    }

    @Override
    @Transactional
    public void fail(Long id, String reason) {
        FactoryAudit audit = getAudit(id);
        audit.setStatus("FAILED");
        audit.setConclusion(audit.getConclusion() + " | 不通过原因: " + reason);
        factoryAuditRepository.save(audit);
    }

    private FactoryAudit getAudit(Long id) {
        return factoryAuditRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("验厂记录不存在: " + id));
    }

    private FactoryAuditResponse toResponse(FactoryAudit a) {
        FactoryAuditResponse r = new FactoryAuditResponse();
        r.setId(a.getId());
        r.setAuditNo(a.getAuditNo());
        r.setSupplierId(a.getSupplierId());
        r.setCompanyName(a.getCompanyName());
        r.setFactoryAddress(a.getFactoryAddress());
        r.setAuditType(a.getAuditType());
        r.setAuditItems(a.getAuditItems());
        r.setAuditorName(a.getAuditorName());
        r.setAuditorId(a.getAuditorId());
        r.setAuditDate(a.getAuditDate());
        r.setProductionCapacity(a.getProductionCapacity());
        r.setEmployeeCount(a.getEmployeeCount());
        r.setFactoryArea(a.getFactoryArea());
        r.setEquipmentList(a.getEquipmentList());
        r.setQualitySystem(a.getQualitySystem());
        r.setPhotos(a.getPhotos());
        r.setOverallScore(a.getOverallScore());
        r.setConclusion(a.getConclusion());
        r.setStatus(a.getStatus());
        r.setNextAuditDate(a.getNextAuditDate());
        r.setCreatedAt(a.getCreatedAt());
        return r;
    }
}
