package com.yicai.trade.module.certification.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.certification.dto.*;
import com.yicai.trade.module.certification.entity.Certification;
import com.yicai.trade.module.certification.repository.CertificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CertificationServiceImpl implements CertificationService {

    private final CertificationRepository certificationRepository;

    @Override
    @Transactional
    public CertificationResponse create(Long userId, CertificationRequest request) {
        Certification cert = Certification.builder()
                .certNo("CERT" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")))
                .userId(userId)
                .companyId(request.getCompanyId())
                .companyName(request.getCompanyName())
                .creditCode(request.getCreditCode())
                .companyType(request.getCompanyType())
                .registeredCapital(request.getRegisteredCapital())
                .foundDate(request.getFoundDate() != null ? LocalDate.parse(request.getFoundDate()) : null)
                .companyAddress(request.getCompanyAddress())
                .legalName(request.getLegalName())
                .legalIdNumber(request.getLegalIdNumber())
                .legalPhone(request.getLegalPhone())
                .legalIdFront(request.getLegalIdFront())
                .legalIdBack(request.getLegalIdBack())
                .businessLicense(request.getBusinessLicense())
                .certType(request.getCertType())
                .otherCerts(request.getOtherCerts())
                .contactName(request.getContactName())
                .contactTitle(request.getContactTitle())
                .contactPhone(request.getContactPhone())
                .contactEmail(request.getContactEmail())
                .status("PENDING")
                .build();
        return toResponse(certificationRepository.save(cert));
    }

    @Override
    public List<CertificationResponse> getMyList(Long userId) {
        return certificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public CertificationResponse getById(Long id) {
        return certificationRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("Certification not found: " + id));
    }

    @Override
    public PageResult<CertificationResponse> list(String status, String certType, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Certification> p;
        if (status != null && !status.isEmpty()) {
            p = certificationRepository.findByStatus(status, pageable);
        } else if (certType != null && !certType.isEmpty()) {
            p = certificationRepository.findByCertType(certType, pageable);
        } else {
            p = certificationRepository.findAll(pageable);
        }
        List<CertificationResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void audit(Long id, String action, String remark, String auditor) {
        Certification cert = certificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Certification not found: " + id));
        cert.setStatus("APPROVE".equals(action) ? "APPROVED" : "REJECTED");
        cert.setAuditRemark(remark);
        cert.setAuditedBy(auditor);
        cert.setAuditedAt(LocalDateTime.now());
        if ("APPROVE".equals(action)) {
            cert.setExpireAt(LocalDateTime.now().plusYears(1));
        }
        certificationRepository.save(cert);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", certificationRepository.count());
        stats.put("pending", certificationRepository.countByStatus("PENDING"));
        stats.put("approved", certificationRepository.countByStatus("APPROVED"));
        stats.put("rejected", certificationRepository.countByStatus("REJECTED"));
        return stats;
    }

    private CertificationResponse toResponse(Certification c) {
        CertificationResponse r = new CertificationResponse();
        r.setId(c.getId());
        r.setCertNo(c.getCertNo());
        r.setUserId(c.getUserId());
        r.setCompanyId(c.getCompanyId());
        r.setCompanyName(c.getCompanyName());
        r.setCreditCode(c.getCreditCode());
        r.setCompanyType(c.getCompanyType());
        r.setRegisteredCapital(c.getRegisteredCapital());
        r.setFoundDate(c.getFoundDate());
        r.setCompanyAddress(c.getCompanyAddress());
        r.setLegalName(c.getLegalName());
        r.setLegalIdNumber(c.getLegalIdNumber());
        r.setLegalPhone(c.getLegalPhone());
        r.setLegalIdFront(c.getLegalIdFront());
        r.setLegalIdBack(c.getLegalIdBack());
        r.setBusinessLicense(c.getBusinessLicense());
        r.setCertType(c.getCertType());
        r.setOtherCerts(c.getOtherCerts());
        r.setContactName(c.getContactName());
        r.setContactTitle(c.getContactTitle());
        r.setContactPhone(c.getContactPhone());
        r.setContactEmail(c.getContactEmail());
        r.setMaterials(c.getMaterials());
        r.setStatus(c.getStatus());
        r.setAuditRemark(c.getAuditRemark());
        r.setAuditedBy(c.getAuditedBy());
        r.setAuditedAt(c.getAuditedAt());
        r.setExpireAt(c.getExpireAt());
        r.setCreatedAt(c.getCreatedAt());
        return r;
    }
}
