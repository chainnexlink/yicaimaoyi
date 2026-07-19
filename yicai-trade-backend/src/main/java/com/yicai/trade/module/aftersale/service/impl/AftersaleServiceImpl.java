package com.yicai.trade.module.aftersale.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.aftersale.dto.*;
import com.yicai.trade.module.aftersale.entity.Aftersale;
import com.yicai.trade.module.aftersale.entity.AftersaleLog;
import com.yicai.trade.module.aftersale.repository.AftersaleLogRepository;
import com.yicai.trade.module.aftersale.repository.AftersaleRepository;
import com.yicai.trade.module.aftersale.service.AftersaleService;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.payment.dto.RefundCreateRequest;
import com.yicai.trade.module.payment.service.PaymentService;
import com.yicai.trade.module.score.service.SupplierCreditService;
import com.yicai.trade.module.message.service.MessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AftersaleServiceImpl implements AftersaleService {

    private final AftersaleRepository aftersaleRepository;
    private final AftersaleLogRepository aftersaleLogRepository;
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final SupplierCreditService creditService;
    private final MessageService messageService;

    @Override
    @Transactional
    public AftersaleResponse create(AftersaleCreateRequest req) {
        // 验证订单存在
        orderRepository.findById(req.getOrderId())
                .orElseThrow(() -> new RuntimeException("关联订单不存在: " + req.getOrderId()));

        Aftersale as = Aftersale.builder()
                .aftersaleNo("AS" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmssSSS")))
                .orderId(req.getOrderId())
                .orderNo(req.getOrderNo())
                .buyerId(req.getBuyerId())
                .supplierId(req.getSupplierId())
                .type(req.getType())
                .reasonType(req.getReasonType())
                .reason(req.getReason())
                .evidenceUrls(req.getEvidenceUrls())
                .refundAmount(req.getRefundAmount())
                .status("PENDING")
                .build();
        as = aftersaleRepository.save(as);
        addLog(as.getId(), req.getBuyerId(), "买家", "BUYER", "SUBMIT", null, "PENDING", "提交售后申请");

        // 更新供应商信用评分
        try {
            creditService.onAftersaleCreated(req.getSupplierId(), as.getId());
        } catch (Exception e) {
            log.warn("更新供应商信用评分失败，不影响售后创建: {}", e.getMessage());
        }

        // 通知供应商有新的售后申请
        try {
            String typeLabel = "RETURN".equals(req.getType()) ? "退货退款" :
                    "EXCHANGE".equals(req.getType()) ? "换货" : "售后服务";
            messageService.sendSystemNotification(req.getSupplierId(),
                    "AFTERSALE", "您有一条新的售后申请",
                    "售后单号：" + as.getAftersaleNo() + "，类型：" + typeLabel
                            + "，关联订单：" + as.getOrderNo() + "，请及时处理。",
                    as.getId(), "AFTERSALE");
        } catch (Exception e) {
            log.warn("售后创建通知供应商失败: aftersaleId={}, supplierId={}", as.getId(), req.getSupplierId());
        }

        return toResponse(as);
    }

    @Override
    public AftersaleResponse getById(Long id) {
        Aftersale as = aftersaleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("售后单不存在: " + id));
        AftersaleResponse resp = toResponse(as);
        List<AftersaleLog> logs = aftersaleLogRepository.findByAftersaleIdOrderByCreatedAtAsc(id);
        resp.setLogs(logs.stream().map(this::toLogResponse).collect(Collectors.toList()));
        return resp;
    }

    @Override
    public PageResult<AftersaleResponse> list(String status, String type, Long buyerId, Long supplierId, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Aftersale> p;
        if (status != null && !status.isEmpty()) {
            p = aftersaleRepository.findByStatus(status, pageable);
        } else if (type != null && !type.isEmpty()) {
            p = aftersaleRepository.findByType(type, pageable);
        } else if (buyerId != null) {
            p = aftersaleRepository.findByBuyerId(buyerId, pageable);
        } else if (supplierId != null) {
            p = aftersaleRepository.findBySupplierId(supplierId, pageable);
        } else {
            p = aftersaleRepository.findAll(pageable);
        }
        List<AftersaleResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void supplierApprove(Long id, Long operatorId, String remark) {
        Aftersale as = getAftersale(id, "PENDING");
        as.setStatus("SUPPLIER_APPROVED");
        as.setSupplierRemark(remark);
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "SUPPLIER", "APPROVE", "PENDING", "SUPPLIER_APPROVED", remark);
    }

    @Override
    @Transactional
    public void supplierReject(Long id, Long operatorId, String remark) {
        Aftersale as = getAftersale(id, "PENDING");
        as.setStatus("REJECTED");
        as.setSupplierRemark(remark);
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "SUPPLIER", "REJECT", "PENDING", "REJECTED", remark);
    }

    @Override
    @Transactional
    public void buyerShipReturn(Long id, Long operatorId, String trackingNo, String carrier) {
        Aftersale as = getAftersale(id, "SUPPLIER_APPROVED");
        as.setStatus("BUYER_SHIPPED");
        as.setReturnTrackingNo(trackingNo);
        as.setReturnCarrier(carrier);
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "BUYER", "SHIP", "SUPPLIER_APPROVED", "BUYER_SHIPPED",
                "退回物流: " + carrier + " " + trackingNo);
    }

    @Override
    @Transactional
    public void supplierConfirmReceive(Long id, Long operatorId) {
        Aftersale as = getAftersale(id, "BUYER_SHIPPED");
        as.setStatus("SUPPLIER_RECEIVED");
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "SUPPLIER", "RECEIVE", "BUYER_SHIPPED", "SUPPLIER_RECEIVED", "供应商已收到退回商品");
    }

    @Override
    @Transactional
    public void executeRefund(Long id, Long operatorId) {
        Aftersale as = aftersaleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("售后单不存在: " + id));
        String oldStatus = as.getStatus();

        // 调用支付模块发起退款
        try {
            RefundCreateRequest refundReq = new RefundCreateRequest();
            refundReq.setOrderId(as.getOrderId());
            refundReq.setRefundAmount(as.getRefundAmount());
            refundReq.setRefundReason("售后退款 - " + as.getAftersaleNo());
            refundReq.setRefundType("RETURN".equals(as.getType()) ? "FULL" : "PARTIAL");
            paymentService.createRefund(refundReq, operatorId);
        } catch (Exception e) {
            log.error("售后退款调用支付服务失败，售后单: {}，错误: {}", as.getAftersaleNo(), e.getMessage());
            throw new RuntimeException("退款执行失败: " + e.getMessage());
        }

        as.setStatus("REFUNDED");
        as.setResolvedAt(LocalDateTime.now());
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "PLATFORM", "REFUND", oldStatus, "REFUNDED",
                "退款金额: " + as.getRefundAmount());
    }

    @Override
    @Transactional
    public void executeExchange(Long id, Long operatorId, String trackingNo, String carrier) {
        Aftersale as = getAftersale(id, "SUPPLIER_RECEIVED");
        as.setStatus("EXCHANGED");
        as.setExchangeTrackingNo(trackingNo);
        as.setExchangeCarrier(carrier);
        as.setResolvedAt(LocalDateTime.now());
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "SUPPLIER", "EXCHANGE", "SUPPLIER_RECEIVED", "EXCHANGED",
                "换货物流: " + carrier + " " + trackingNo);
    }

    @Override
    @Transactional
    public void complete(Long id, Long operatorId) {
        Aftersale as = aftersaleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("售后单不存在: " + id));
        String oldStatus = as.getStatus();
        as.setStatus("COMPLETED");
        as.setResolvedAt(LocalDateTime.now());
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "BUYER", "CLOSE", oldStatus, "COMPLETED", "买家确认售后完成");
    }

    @Override
    @Transactional
    public void buyerAppeal(Long id, Long operatorId, String reason) {
        Aftersale as = getAftersale(id, "REJECTED");
        as.setStatus("APPEAL");
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "BUYER", "APPEAL", "REJECTED", "APPEAL", reason);
    }

    @Override
    @Transactional
    public void platformIntervene(Long id, Long operatorId, String decision, String remark) {
        Aftersale as = aftersaleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("售后单不存在: " + id));
        String oldStatus = as.getStatus();
        as.setStatus("PLATFORM_RESOLVED");
        as.setPlatformRemark(remark);
        as.setResolvedAt(LocalDateTime.now());
        aftersaleRepository.save(as);
        addLog(id, operatorId, null, "PLATFORM", "INTERVENE", oldStatus, "PLATFORM_RESOLVED",
                "平台裁决: " + decision + " - " + remark);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", aftersaleRepository.count());
        stats.put("pending", aftersaleRepository.countByStatus("PENDING"));
        stats.put("processing", aftersaleRepository.countByStatus("SUPPLIER_APPROVED")
                + aftersaleRepository.countByStatus("BUYER_SHIPPED")
                + aftersaleRepository.countByStatus("SUPPLIER_RECEIVED"));
        stats.put("appeal", aftersaleRepository.countByStatus("APPEAL"));
        stats.put("completed", aftersaleRepository.countByStatus("COMPLETED")
                + aftersaleRepository.countByStatus("REFUNDED")
                + aftersaleRepository.countByStatus("EXCHANGED")
                + aftersaleRepository.countByStatus("PLATFORM_RESOLVED"));
        return stats;
    }

    private Aftersale getAftersale(Long id, String expectedStatus) {
        Aftersale as = aftersaleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("售后单不存在: " + id));
        if (!expectedStatus.equals(as.getStatus())) {
            throw new RuntimeException("当前状态[" + as.getStatus() + "]不允许此操作，需要状态: " + expectedStatus);
        }
        return as;
    }

    private void addLog(Long aftersaleId, Long operatorId, String operatorName,
                        String operatorRole, String action, String fromStatus, String toStatus, String remark) {
        AftersaleLog log = AftersaleLog.builder()
                .aftersaleId(aftersaleId)
                .operatorId(operatorId)
                .operatorName(operatorName)
                .operatorRole(operatorRole)
                .action(action)
                .fromStatus(fromStatus)
                .toStatus(toStatus)
                .remark(remark)
                .build();
        aftersaleLogRepository.save(log);
    }

    private AftersaleResponse toResponse(Aftersale as) {
        AftersaleResponse r = new AftersaleResponse();
        r.setId(as.getId());
        r.setAftersaleNo(as.getAftersaleNo());
        r.setOrderId(as.getOrderId());
        r.setOrderNo(as.getOrderNo());
        r.setBuyerId(as.getBuyerId());
        r.setSupplierId(as.getSupplierId());
        r.setType(as.getType());
        r.setReasonType(as.getReasonType());
        r.setReason(as.getReason());
        r.setEvidenceUrls(as.getEvidenceUrls());
        r.setRefundAmount(as.getRefundAmount());
        r.setReturnTrackingNo(as.getReturnTrackingNo());
        r.setReturnCarrier(as.getReturnCarrier());
        r.setExchangeTrackingNo(as.getExchangeTrackingNo());
        r.setExchangeCarrier(as.getExchangeCarrier());
        r.setStatus(as.getStatus());
        r.setSupplierRemark(as.getSupplierRemark());
        r.setPlatformRemark(as.getPlatformRemark());
        r.setResolvedAt(as.getResolvedAt());
        r.setCreatedAt(as.getCreatedAt());
        r.setUpdatedAt(as.getUpdatedAt());
        return r;
    }

    private AftersaleLogResponse toLogResponse(AftersaleLog log) {
        AftersaleLogResponse r = new AftersaleLogResponse();
        r.setId(log.getId());
        r.setOperatorId(log.getOperatorId());
        r.setOperatorName(log.getOperatorName());
        r.setOperatorRole(log.getOperatorRole());
        r.setAction(log.getAction());
        r.setFromStatus(log.getFromStatus());
        r.setToStatus(log.getToStatus());
        r.setRemark(log.getRemark());
        r.setCreatedAt(log.getCreatedAt());
        return r;
    }
}
