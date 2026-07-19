package com.yicai.trade.module.dispute.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.dispute.dto.*;
import com.yicai.trade.module.dispute.entity.Dispute;
import com.yicai.trade.module.dispute.entity.DisputeMessage;
import com.yicai.trade.module.dispute.repository.DisputeMessageRepository;
import com.yicai.trade.module.dispute.repository.DisputeRepository;
import com.yicai.trade.module.dispute.service.DisputeService;
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

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class DisputeServiceImpl implements DisputeService {

    private final DisputeRepository disputeRepository;
    private final DisputeMessageRepository disputeMessageRepository;
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final SupplierCreditService creditService;
    private final MessageService messageService;

    @Override
    @Transactional
    public DisputeResponse create(DisputeCreateRequest req) {
        // 验证订单存在
        orderRepository.findById(req.getOrderId())
                .orElseThrow(() -> new RuntimeException("关联订单不存在: " + req.getOrderId()));

        Dispute d = Dispute.builder()
                .disputeNo("DSP" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmssSSS")))
                .orderId(req.getOrderId())
                .orderNo(req.getOrderNo())
                .aftersaleId(req.getAftersaleId())
                .initiatorId(req.getInitiatorId())
                .initiatorRole(req.getInitiatorRole())
                .respondentId(req.getRespondentId())
                .respondentRole(req.getRespondentRole())
                .disputeType(req.getDisputeType())
                .severity(req.getSeverity() != null ? req.getSeverity() : "NORMAL")
                .description(req.getDescription())
                .evidenceUrls(req.getEvidenceUrls())
                .claimAmount(req.getClaimAmount())
                .status("OPEN")
                .build();
        d = disputeRepository.save(d);

        addSystemMessage(d.getId(), "纠纷已创建，等待平台受理");

        // 通知被投诉方
        try {
            String respondentLabel = "SUPPLIER".equals(d.getRespondentRole()) ? "供应商" : "采购商";
            messageService.sendSystemNotification(d.getRespondentId(),
                    "DISPUTE", "您有一条新的纠纷投诉",
                    "纠纷单号：" + d.getDisputeNo() + "，类型：" + d.getDisputeType()
                            + "，您作为" + respondentLabel + "被发起纠纷投诉，请及时查看并响应。",
                    d.getId(), "DISPUTE");
        } catch (Exception e) {
            log.warn("纠纷创建通知被投诉方失败: disputeId={}, respondentId={}", d.getId(), d.getRespondentId());
        }

        return toResponse(d);
    }

    @Override
    public DisputeResponse getById(Long id) {
        Dispute d = disputeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("纠纷不存在: " + id));
        DisputeResponse resp = toResponse(d);
        List<DisputeMessage> msgs = disputeMessageRepository.findByDisputeIdOrderByCreatedAtAsc(id);
        resp.setMessages(msgs.stream().map(this::toMsgResponse).collect(Collectors.toList()));
        return resp;
    }

    @Override
    public PageResult<DisputeResponse> list(String status, String disputeType, Long assignedTo, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Dispute> p;
        if (assignedTo != null) {
            p = disputeRepository.findByAssignedTo(assignedTo, pageable);
        } else if (status != null && !status.isEmpty()) {
            p = disputeRepository.findByStatus(status, pageable);
        } else if (disputeType != null && !disputeType.isEmpty()) {
            p = disputeRepository.findByDisputeType(disputeType, pageable);
        } else {
            p = disputeRepository.findAll(pageable);
        }
        List<DisputeResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void assignTo(Long disputeId, Long staffId) {
        Dispute d = getDispute(disputeId);
        d.setAssignedTo(staffId);
        disputeRepository.save(d);
        addSystemMessage(disputeId, "纠纷已分配给处理人员 #" + staffId);
    }

    @Override
    @Transactional
    public void startReview(Long disputeId, Long operatorId) {
        Dispute d = getDispute(disputeId);
        d.setStatus("UNDER_REVIEW");
        disputeRepository.save(d);
        addSystemMessage(disputeId, "平台已受理，正在审核中");
    }

    @Override
    @Transactional
    public void startMediation(Long disputeId, Long operatorId, String message) {
        Dispute d = getDispute(disputeId);
        d.setStatus("MEDIATION");
        disputeRepository.save(d);
        addSystemMessage(disputeId, "进入调解阶段: " + message);
    }

    @Override
    @Transactional
    public void makeRuling(Long disputeId, Long operatorId, String rulingType, BigDecimal awardedAmount, String reason) {
        Dispute d = getDispute(disputeId);
        d.setStatus("RULING");
        d.setRulingType(rulingType);
        d.setAwardedAmount(awardedAmount);
        d.setRulingReason(reason);
        d.setRuledAt(LocalDateTime.now());
        disputeRepository.save(d);
        addSystemMessage(disputeId, "平台裁决: " + rulingType + "，金额: " + awardedAmount + "，原因: " + reason);
    }

    @Override
    @Transactional
    public void enforce(Long disputeId, Long operatorId) {
        Dispute d = getDispute(disputeId);

        // 根据裁决类型执行退款/赔偿
        if (d.getAwardedAmount() != null && d.getAwardedAmount().compareTo(BigDecimal.ZERO) > 0
                && d.getRulingType() != null && !"REJECT".equals(d.getRulingType())) {
            try {
                RefundCreateRequest refundReq = new RefundCreateRequest();
                refundReq.setOrderId(d.getOrderId());
                refundReq.setRefundAmount(d.getAwardedAmount());
                refundReq.setRefundReason("纠纷裁决执行 - " + d.getDisputeNo() + " (" + d.getRulingType() + ")");
                refundReq.setRefundType("FULL_REFUND".equals(d.getRulingType()) ? "FULL" : "PARTIAL");
                paymentService.createRefund(refundReq, operatorId);
            } catch (Exception e) {
                log.error("纠纷裁决执行退款失败，纠纷单: {}，错误: {}", d.getDisputeNo(), e.getMessage());
                throw new RuntimeException("裁决执行失败: " + e.getMessage());
            }
        }

        d.setStatus("ENFORCING");
        disputeRepository.save(d);

        // 同步更新关联订单状态
        if (d.getOrderId() != null) {
            try {
                orderRepository.findById(d.getOrderId()).ifPresent(order -> {
                    if (!"COMPLETED".equals(order.getStatus()) && !"CANCELLED".equals(order.getStatus())) {
                        order.setStatus("DISPUTE_PROCESSING");
                        orderRepository.save(order);
                        log.info("纠纷裁决执行，订单状态已更新: orderId={}, newStatus=DISPUTE_PROCESSING", d.getOrderId());
                    }
                });
            } catch (Exception e) {
                log.warn("纠纷裁决同步订单状态失败: orderId={}, error={}", d.getOrderId(), e.getMessage());
            }
        }

        addSystemMessage(disputeId, "裁决执行中");
    }

    @Override
    @Transactional
    public void close(Long disputeId, Long operatorId, String remark) {
        Dispute d = getDispute(disputeId);
        d.setStatus("CLOSED");
        d.setClosedAt(LocalDateTime.now());
        disputeRepository.save(d);
        addSystemMessage(disputeId, "纠纷已关闭: " + remark);

        // 更新供应商信用评分 - 确定被诉方是否为供应商
        try {
            Long supplierId = "SUPPLIER".equals(d.getRespondentRole()) ? d.getRespondentId() : d.getInitiatorId();
            boolean supplierLost = "SUPPLIER".equals(d.getRespondentRole())
                    && d.getRulingType() != null && !"REJECT".equals(d.getRulingType());
            creditService.onDisputeResolved(supplierId, disputeId, supplierLost);
        } catch (Exception e) {
            log.warn("更新供应商信用评分失败，不影响纠纷关闭: {}", e.getMessage());
        }
    }

    @Override
    @Transactional
    public void withdraw(Long disputeId, Long operatorId, String reason) {
        Dispute d = getDispute(disputeId);
        d.setStatus("WITHDRAWN");
        d.setClosedAt(LocalDateTime.now());
        disputeRepository.save(d);
        addSystemMessage(disputeId, "发起方撤回纠纷: " + reason);
    }

    @Override
    @Transactional
    public void addMessage(Long disputeId, Long senderId, String senderRole, String content, String attachmentUrls) {
        DisputeMessage msg = DisputeMessage.builder()
                .disputeId(disputeId)
                .senderId(senderId)
                .senderRole(senderRole)
                .content(content)
                .attachmentUrls(attachmentUrls)
                .msgType("TEXT")
                .build();
        disputeMessageRepository.save(msg);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", disputeRepository.count());
        stats.put("open", disputeRepository.countByStatus("OPEN"));
        stats.put("underReview", disputeRepository.countByStatus("UNDER_REVIEW"));
        stats.put("mediation", disputeRepository.countByStatus("MEDIATION"));
        stats.put("ruling", disputeRepository.countByStatus("RULING"));
        stats.put("enforcing", disputeRepository.countByStatus("ENFORCING"));
        stats.put("closed", disputeRepository.countByStatus("CLOSED"));
        return stats;
    }

    private Dispute getDispute(Long id) {
        return disputeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("纠纷不存在: " + id));
    }

    private void addSystemMessage(Long disputeId, String content) {
        DisputeMessage msg = DisputeMessage.builder()
                .disputeId(disputeId)
                .senderId(0L)
                .senderRole("PLATFORM")
                .content(content)
                .msgType("SYSTEM")
                .build();
        disputeMessageRepository.save(msg);
    }

    private DisputeResponse toResponse(Dispute d) {
        DisputeResponse r = new DisputeResponse();
        r.setId(d.getId());
        r.setDisputeNo(d.getDisputeNo());
        r.setOrderId(d.getOrderId());
        r.setOrderNo(d.getOrderNo());
        r.setAftersaleId(d.getAftersaleId());
        r.setInitiatorId(d.getInitiatorId());
        r.setInitiatorRole(d.getInitiatorRole());
        r.setRespondentId(d.getRespondentId());
        r.setRespondentRole(d.getRespondentRole());
        r.setDisputeType(d.getDisputeType());
        r.setSeverity(d.getSeverity());
        r.setDescription(d.getDescription());
        r.setEvidenceUrls(d.getEvidenceUrls());
        r.setClaimAmount(d.getClaimAmount());
        r.setAwardedAmount(d.getAwardedAmount());
        r.setRulingType(d.getRulingType());
        r.setRulingReason(d.getRulingReason());
        r.setAssignedTo(d.getAssignedTo());
        r.setStatus(d.getStatus());
        r.setRuledAt(d.getRuledAt());
        r.setClosedAt(d.getClosedAt());
        r.setCreatedAt(d.getCreatedAt());
        r.setUpdatedAt(d.getUpdatedAt());
        return r;
    }

    private DisputeMessageResponse toMsgResponse(DisputeMessage m) {
        DisputeMessageResponse r = new DisputeMessageResponse();
        r.setId(m.getId());
        r.setSenderId(m.getSenderId());
        r.setSenderRole(m.getSenderRole());
        r.setContent(m.getContent());
        r.setAttachmentUrls(m.getAttachmentUrls());
        r.setMsgType(m.getMsgType());
        r.setCreatedAt(m.getCreatedAt());
        return r;
    }
}
