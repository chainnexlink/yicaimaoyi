package com.yicai.trade.module.payment.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.module.auth.entity.User;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.payment.dto.*;
import com.yicai.trade.module.payment.entity.Payment;
import com.yicai.trade.module.payment.entity.PaymentOperationLog;
import com.yicai.trade.module.payment.entity.Refund;
import com.yicai.trade.module.payment.event.PaymentSuccessEvent;
import com.yicai.trade.module.payment.event.RefundSuccessEvent;
import com.yicai.trade.module.payment.gateway.*;
import com.yicai.trade.module.payment.repository.PaymentOperationLogRepository;
import com.yicai.trade.module.payment.repository.PaymentRepository;
import com.yicai.trade.module.payment.repository.RefundRepository;
import com.yicai.trade.module.payment.service.PaymentService;
import com.yicai.trade.module.supplier.entity.Supplier;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {

    private static final Set<String> SUPPORTED_PAYMENT_METHODS = Set.of(
            "STRIPE", "PAYPAL", "BANK_TRANSFER", "TT_TRANSFER", "LETTER_OF_CREDIT");
    private static final Set<String> MANUAL_PAYMENT_METHODS = Set.of(
            "BANK_TRANSFER", "TT_TRANSFER", "LETTER_OF_CREDIT");
    private static final Set<String> ONLINE_PAYMENT_CURRENCIES = Set.of(
            "USD", "EUR", "GBP", "CAD", "AUD", "NZD", "SGD", "HKD",
            "CHF", "SEK", "DKK", "NOK", "PLN", "CZK");

    private final PaymentRepository paymentRepository;
    private final RefundRepository refundRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final SupplierRepository supplierRepository;
    private final PaymentGatewayFactory gatewayFactory;
    private final PaymentOperationLogRepository operationLogRepository;
    private final ApplicationEventPublisher eventPublisher;

    // ==================== 支付相关 ====================

    @Override
    @Transactional
    @SuppressWarnings("null")
    public PaymentResponse createPayment(PaymentCreateRequest request, Long payerId) {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));

        if ("PAID".equals(order.getPaymentStatus())) {
            throw new BusinessException(ErrorCode.PAYMENT_ALREADY_PAID);
        }

        // 检查是否有未完成的支付
        Optional<Payment> pendingPayment = paymentRepository.findByOrderIdAndStatus(request.getOrderId(), "PENDING");
        if (pendingPayment.isPresent()) {
            throw new BusinessException(ErrorCode.PAYMENT_DUPLICATE);
        }

        // 订单金额校验
        if (order.getTotalAmount() != null && request.getAmount().compareTo(order.getTotalAmount()) != 0) {
            throw new BusinessException(ErrorCode.PAYMENT_AMOUNT_MISMATCH);
        }

        User payer = userRepository.findById(payerId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        Supplier supplier = supplierRepository.findById(order.getSupplierId())
                .orElseThrow(() -> new BusinessException(ErrorCode.SUPPLIER_NOT_FOUND));
        User payee = userRepository.findById(supplier.getUserId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        String paymentMethod = normalizePaymentMethod(request.getPaymentMethod());
        if (!SUPPORTED_PAYMENT_METHODS.contains(paymentMethod)) {
            throw new BusinessException(ErrorCode.PAYMENT_METHOD_NOT_SUPPORTED);
        }
        String currency = normalizeCurrency(order.getCurrency());
        if (("STRIPE".equals(paymentMethod) || "PAYPAL".equals(paymentMethod))
                && !ONLINE_PAYMENT_CURRENCIES.contains(currency)) {
            throw new BusinessException(ErrorCode.INVALID_PARAMETER,
                    "该在线通道暂不支持订单币种 " + currency);
        }

        Payment payment = Payment.builder()
                .paymentNo(generatePaymentNo())
                .orderId(order.getId())
                .orderNo(order.getOrderNo())
                .payerId(payerId)
                .payerName(payer.getRealName() != null ? payer.getRealName() : payer.getUsername())
                .payeeId(payee.getId())
                .payeeName(payee.getRealName() != null ? payee.getRealName() : payee.getUsername())
                .amount(request.getAmount())
                .currency(currency)
                .paymentMethod(paymentMethod)
                .paymentChannel(request.getPaymentChannel())
                .bankAccount(request.getBankAccount())
                .bankName(request.getBankName())
                .remark(request.getRemark())
                .status("PENDING")
                .expiredAt(LocalDateTime.now().plusHours(24))
                .build();

        payment = paymentRepository.save(payment);
        recordLog(payment.getId(), payment.getPaymentNo(), null, null, "CREATE", null, "PENDING", null, null, "创建支付");
        log.info("创建支付记录: paymentNo={}, orderId={}, amount={}", payment.getPaymentNo(), order.getId(), request.getAmount());

        return toPaymentResponse(payment);
    }

    @Override
    public PaymentResponse getPaymentById(Long id) {
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));
        return toPaymentResponse(payment);
    }

    @Override
    public PaymentResponse getPaymentByNo(String paymentNo) {
        Payment payment = paymentRepository.findByPaymentNo(paymentNo)
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));
        return toPaymentResponse(payment);
    }

    @Override
    public List<PaymentResponse> getPaymentsByOrderId(Long orderId) {
        return paymentRepository.findByOrderId(orderId).stream()
                .map(this::toPaymentResponse).collect(Collectors.toList());
    }

    @Override
    public Page<PaymentResponse> getPaymentsByPayer(Long payerId, Pageable pageable) {
        return paymentRepository.findByPayerId(payerId, pageable).map(this::toPaymentResponse);
    }

    @Override
    public Page<PaymentResponse> getPaymentsByPayee(Long payeeId, Pageable pageable) {
        return paymentRepository.findByPayeeId(payeeId, pageable).map(this::toPaymentResponse);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public PaymentResponse confirmPayment(Long paymentId, String transactionId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));
        if (!MANUAL_PAYMENT_METHODS.contains(payment.getPaymentMethod())) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID,
                    "在线支付只能由支付机构的已验证结果确认");
        }
        String txId = transactionId == null || transactionId.isBlank()
                ? "MANUAL-" + payment.getPaymentNo() : transactionId.trim();
        return completePayment(payment, txId, "管理员确认线下款项到账", false);
    }

    @Override
    @Transactional
    public PaymentResponse markPaymentProcessing(Long paymentId, String expectedMethod,
                                                 String providerTransactionId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));
        assertPaymentMethod(payment, expectedMethod);
        assertPaymentNotExpired(payment);
        if ("SUCCESS".equals(payment.getStatus())) {
            return toPaymentResponse(payment);
        }
        if ("PROCESSING".equals(payment.getStatus())) {
            if (!Objects.equals(payment.getTransactionId(), providerTransactionId)) {
                throw new BusinessException(ErrorCode.PAYMENT_DUPLICATE,
                        "支付单已绑定其他支付机构会话");
            }
            return toPaymentResponse(payment);
        }
        if (!"PENDING".equals(payment.getStatus())) {
            throw new BusinessException(ErrorCode.PAYMENT_STATUS_INVALID);
        }
        payment.setStatus("PROCESSING");
        payment.setPaymentChannel(normalizePaymentMethod(expectedMethod));
        payment.setTransactionId(providerTransactionId);
        payment = paymentRepository.save(payment);
        recordLog(payment.getId(), payment.getPaymentNo(), null, null, "INITIATE",
                "PENDING", "PROCESSING", payment.getPayerId(), payment.getPayerName(),
                "已创建支付机构会话: " + providerTransactionId);
        return toPaymentResponse(payment);
    }

    @Override
    @Transactional
    public PaymentResponse confirmExternalPayment(Long paymentId, String expectedMethod,
                                                  String providerTransactionId,
                                                  BigDecimal confirmedAmount,
                                                  String confirmedCurrency) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));
        assertPaymentMethod(payment, expectedMethod);
        if (confirmedAmount == null || payment.getAmount().compareTo(confirmedAmount) != 0) {
            throw new BusinessException(ErrorCode.PAYMENT_AMOUNT_MISMATCH);
        }
        if (!normalizeCurrency(payment.getCurrency()).equals(normalizeCurrency(confirmedCurrency))) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "支付币种不匹配");
        }
        return completePayment(payment, providerTransactionId, "支付机构验签及金额校验通过", true);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public PaymentResponse cancelPayment(Long paymentId, String reason) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));

        if (!"PENDING".equals(payment.getStatus())) {
            throw new BusinessException(ErrorCode.PAYMENT_STATUS_INVALID);
        }

        String fromStatus = payment.getStatus();
        payment.setStatus("CANCELLED");
        payment.setRemark(reason);
        payment = paymentRepository.save(payment);

        recordLog(payment.getId(), payment.getPaymentNo(), null, null, "CANCEL", fromStatus, "CANCELLED", null, null, reason);
        log.info("支付取消: paymentNo={}, reason={}", payment.getPaymentNo(), reason);
        return toPaymentResponse(payment);
    }

    // ==================== 退款相关 ====================

    @Override
    @Transactional
    @SuppressWarnings("null")
    public RefundResponse createRefund(RefundCreateRequest request, Long applicantId) {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));

        Payment payment = paymentRepository.findByOrderIdAndStatus(request.getOrderId(), "SUCCESS")
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));

        // 累计退款金额校验
        BigDecimal totalRefunded = refundRepository.findByOrderId(request.getOrderId()).stream()
                .filter(r -> !"REJECTED".equals(r.getStatus()) && !"FAILED".equals(r.getStatus()))
                .map(Refund::getRefundAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (totalRefunded.add(request.getRefundAmount()).compareTo(payment.getAmount()) > 0) {
            throw new BusinessException(ErrorCode.REFUND_AMOUNT_EXCEED);
        }

        User applicant = userRepository.findById(applicantId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        Refund refund = Refund.builder()
                .refundNo(generateRefundNo())
                .paymentId(payment.getId())
                .paymentNo(payment.getPaymentNo())
                .orderId(order.getId())
                .orderNo(order.getOrderNo())
                .applicantId(applicantId)
                .applicantName(applicant.getRealName() != null ? applicant.getRealName() : applicant.getUsername())
                .refundAmount(request.getRefundAmount())
                .refundReason(request.getRefundReason())
                .refundType(request.getRefundType())
                .status("PENDING")
                .build();

        refund = refundRepository.save(refund);
        recordLog(null, null, refund.getId(), refund.getRefundNo(), "REFUND_CREATE", null, "PENDING", applicantId, null, "申请退款: " + request.getRefundReason());
        log.info("创建退款申请: refundNo={}, orderId={}, amount={}", refund.getRefundNo(), order.getId(), request.getRefundAmount());

        return toRefundResponse(refund);
    }

    @Override
    public RefundResponse getRefundById(Long id) {
        Refund refund = refundRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.REFUND_NOT_FOUND));
        return toRefundResponse(refund);
    }

    @Override
    public RefundResponse getRefundByNo(String refundNo) {
        Refund refund = refundRepository.findByRefundNo(refundNo)
                .orElseThrow(() -> new BusinessException(ErrorCode.REFUND_NOT_FOUND));
        return toRefundResponse(refund);
    }

    @Override
    public List<RefundResponse> getRefundsByOrderId(Long orderId) {
        return refundRepository.findByOrderId(orderId).stream()
                .map(this::toRefundResponse).collect(Collectors.toList());
    }

    @Override
    public Page<RefundResponse> getRefundsByApplicant(Long applicantId, Pageable pageable) {
        return refundRepository.findByApplicantId(applicantId, pageable).map(this::toRefundResponse);
    }

    @Override
    public Page<RefundResponse> getPendingRefunds(Pageable pageable) {
        return refundRepository.findByStatus("PENDING", pageable).map(this::toRefundResponse);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public RefundResponse approveRefund(Long refundId, Long auditorId, String remark) {
        Refund refund = refundRepository.findById(refundId)
                .orElseThrow(() -> new BusinessException(ErrorCode.REFUND_NOT_FOUND));
        if (!"PENDING".equals(refund.getStatus())) {
            throw new BusinessException(ErrorCode.REFUND_STATUS_INVALID);
        }

        User auditor = userRepository.findById(auditorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        refund.setStatus("APPROVED");
        refund.setAuditorId(auditorId);
        refund.setAuditorName(auditor.getRealName() != null ? auditor.getRealName() : auditor.getUsername());
        refund.setAuditRemark(remark);
        refund.setAuditedAt(LocalDateTime.now());
        refund = refundRepository.save(refund);

        recordLog(null, null, refund.getId(), refund.getRefundNo(), "REFUND_APPROVE", "PENDING", "APPROVED", auditorId, refund.getAuditorName(), remark);
        log.info("退款审核通过: refundNo={}, auditorId={}", refund.getRefundNo(), auditorId);
        return toRefundResponse(refund);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public RefundResponse rejectRefund(Long refundId, Long auditorId, String remark) {
        Refund refund = refundRepository.findById(refundId)
                .orElseThrow(() -> new BusinessException(ErrorCode.REFUND_NOT_FOUND));
        if (!"PENDING".equals(refund.getStatus())) {
            throw new BusinessException(ErrorCode.REFUND_STATUS_INVALID);
        }

        User auditor = userRepository.findById(auditorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        refund.setStatus("REJECTED");
        refund.setAuditorId(auditorId);
        refund.setAuditorName(auditor.getRealName() != null ? auditor.getRealName() : auditor.getUsername());
        refund.setAuditRemark(remark);
        refund.setAuditedAt(LocalDateTime.now());
        refund = refundRepository.save(refund);

        recordLog(null, null, refund.getId(), refund.getRefundNo(), "REFUND_REJECT", "PENDING", "REJECTED", auditorId, refund.getAuditorName(), remark);
        log.info("退款审核拒绝: refundNo={}, auditorId={}, reason={}", refund.getRefundNo(), auditorId, remark);
        return toRefundResponse(refund);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public RefundResponse processRefund(Long refundId, String transactionId) {
        Refund refund = refundRepository.findById(refundId)
                .orElseThrow(() -> new BusinessException(ErrorCode.REFUND_NOT_FOUND));
        if (!"APPROVED".equals(refund.getStatus())) {
            throw new BusinessException(ErrorCode.REFUND_STATUS_INVALID);
        }

        // 获取原支付记录
        Payment payment = paymentRepository.findById(refund.getPaymentId())
                .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));

        // 通过网关执行退款
        PaymentGateway gateway = gatewayFactory.getGateway(payment.getPaymentMethod());
        GatewayRefundResult result = gateway.refund(GatewayRefundRequest.builder()
                .refundNo(refund.getRefundNo())
                .originalTransactionId(payment.getTransactionId())
                .refundAmount(refund.getRefundAmount())
                .currency(payment.getCurrency())
                .reason(refund.getRefundReason())
                .build());

        if (!result.isSuccess()) {
            refund.setStatus("FAILED");
            refundRepository.save(refund);
            recordLog(null, null, refund.getId(), refund.getRefundNo(), "REFUND_PROCESS", "APPROVED", "FAILED", null, null, "退款网关失败: " + result.getMessage());
            throw new BusinessException(ErrorCode.PAYMENT_GATEWAY_ERROR);
        }

        String txId = transactionId != null ? transactionId : result.getTransactionId();
        refund.setStatus("SUCCESS");
        refund.setTransactionId(txId);
        refund.setRefundedAt(LocalDateTime.now());
        refund = refundRepository.save(refund);

        // 更新订单支付状态
        Order order = orderRepository.findById(refund.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        order.setPaymentStatus("REFUNDED");
        orderRepository.save(order);

        recordLog(null, null, refund.getId(), refund.getRefundNo(), "REFUND_PROCESS", "APPROVED", "SUCCESS", null, null, "退款成功, txId=" + txId);

        // 发布退款成功事件（异步扣减积分）
        eventPublisher.publishEvent(new RefundSuccessEvent(this, refund.getId(), refund.getOrderId(), refund.getApplicantId(), refund.getRefundAmount()));

        log.info("退款处理成功: refundNo={}, transactionId={}", refund.getRefundNo(), txId);
        return toRefundResponse(refund);
    }

    // ==================== 管理后台 ====================

    @Override
    public Page<PaymentResponse> getAllPayments(String status, Pageable pageable) {
        if (status != null && !status.isBlank()) {
            return paymentRepository.findByStatus(status, pageable).map(this::toPaymentResponse);
        }
        return paymentRepository.findAll(pageable).map(this::toPaymentResponse);
    }

    @Override
    public Page<RefundResponse> getAllRefunds(String status, Pageable pageable) {
        if (status != null && !status.isBlank()) {
            return refundRepository.findByStatus(status, pageable).map(this::toRefundResponse);
        }
        return refundRepository.findAll(pageable).map(this::toRefundResponse);
    }

    @Override
    public Map<String, Object> getPaymentStatistics() {
        Map<String, Object> stats = new HashMap<>();
        long totalCount = paymentRepository.count();
        long successCount = paymentRepository.countByStatus("SUCCESS");
        long pendingCount = paymentRepository.countByStatus("PENDING");
        long expiredCount = paymentRepository.countByStatus("EXPIRED");
        long cancelledCount = paymentRepository.countByStatus("CANCELLED");
        long failedCount = paymentRepository.countByStatus("FAILED");

        stats.put("totalCount", totalCount);
        stats.put("successCount", successCount);
        stats.put("pendingCount", pendingCount);
        stats.put("expiredCount", expiredCount);
        stats.put("cancelledCount", cancelledCount);
        stats.put("failedCount", failedCount);
        stats.put("successRate", totalCount > 0 ? String.format("%.1f%%", (double) successCount / totalCount * 100) : "0%");

        // 总成功金额
        BigDecimal totalSuccessAmount = paymentRepository.sumAmountByStatus("SUCCESS");
        stats.put("totalSuccessAmount", totalSuccessAmount != null ? totalSuccessAmount : BigDecimal.ZERO);

        // 退款统计
        long refundTotal = refundRepository.count();
        long refundSuccess = refundRepository.countByStatus("SUCCESS");
        long refundPending = refundRepository.countByStatus("PENDING");
        stats.put("refundTotal", refundTotal);
        stats.put("refundSuccess", refundSuccess);
        stats.put("refundPending", refundPending);

        BigDecimal totalRefundAmount = refundRepository.sumRefundAmountByStatus("SUCCESS");
        stats.put("totalRefundAmount", totalRefundAmount != null ? totalRefundAmount : BigDecimal.ZERO);

        return stats;
    }

    // ==================== 内部方法 ====================

    private void recordLog(Long paymentId, String paymentNo, Long refundId, String refundNo,
                           String operationType, String fromStatus, String toStatus,
                           Long operatorId, String operatorName, String remark) {
        PaymentOperationLog logEntry = PaymentOperationLog.builder()
                .paymentId(paymentId)
                .paymentNo(paymentNo)
                .refundId(refundId)
                .refundNo(refundNo)
                .operationType(operationType)
                .fromStatus(fromStatus)
                .toStatus(toStatus)
                .operatorId(operatorId)
                .operatorName(operatorName)
                .remark(remark)
                .build();
        operationLogRepository.save(logEntry);
    }

    private String generatePaymentNo() {
        String dateStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String uuid = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
        return "PAY" + dateStr + uuid;
    }

    private String generateRefundNo() {
        String dateStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String uuid = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
        return "REF" + dateStr + uuid;
    }

    private PaymentResponse toPaymentResponse(Payment payment) {
        return PaymentResponse.builder()
                .id(payment.getId())
                .paymentNo(payment.getPaymentNo())
                .orderId(payment.getOrderId())
                .orderNo(payment.getOrderNo())
                .payerId(payment.getPayerId())
                .payerName(payment.getPayerName())
                .payeeId(payment.getPayeeId())
                .payeeName(payment.getPayeeName())
                .amount(payment.getAmount())
                .currency(payment.getCurrency())
                .paymentMethod(payment.getPaymentMethod())
                .paymentChannel(payment.getPaymentChannel())
                .status(payment.getStatus())
                .transactionId(payment.getTransactionId())
                .bankAccount(payment.getBankAccount())
                .bankName(payment.getBankName())
                .remark(payment.getRemark())
                .paidAt(payment.getPaidAt())
                .expiredAt(payment.getExpiredAt())
                .createdAt(payment.getCreatedAt())
                .build();
    }

    private PaymentResponse completePayment(Payment payment, String transactionId, String remark,
                                            boolean providerAlreadyCollectedFunds) {
        if ("SUCCESS".equals(payment.getStatus())) {
            return toPaymentResponse(payment);
        }
        String fromStatus = payment.getStatus();
        if (!"PENDING".equals(fromStatus) && !"PROCESSING".equals(fromStatus)
                && !(providerAlreadyCollectedFunds && "EXPIRED".equals(fromStatus))) {
            throw new BusinessException(ErrorCode.PAYMENT_STATUS_INVALID);
        }
        if (!providerAlreadyCollectedFunds) {
            assertPaymentNotExpired(payment);
        }
        if (transactionId == null || transactionId.isBlank()) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "支付机构交易号不能为空");
        }

        payment.setStatus("SUCCESS");
        payment.setTransactionId(transactionId.trim());
        payment.setPaidAt(LocalDateTime.now());
        payment = paymentRepository.save(payment);

        Order order = orderRepository.findById(payment.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
        order.setPaymentStatus("PAID");
        order.setPaymentMethod(payment.getPaymentMethod());
        if ("PENDING".equals(order.getStatus()) || "CONFIRMED".equals(order.getStatus())) {
            order.setStatus("PAID");
        }
        orderRepository.save(order);

        recordLog(payment.getId(), payment.getPaymentNo(), null, null, "CONFIRM", fromStatus,
                "SUCCESS", null, null, remark + ", txId=" + transactionId);
        eventPublisher.publishEvent(new PaymentSuccessEvent(this, payment.getId(), payment.getOrderId(),
                payment.getPayerId(), payment.getAmount()));
        log.info("支付确认成功: paymentNo={}, method={}, transactionId={}",
                payment.getPaymentNo(), payment.getPaymentMethod(), transactionId);
        return toPaymentResponse(payment);
    }

    private void assertPaymentMethod(Payment payment, String expectedMethod) {
        if (!Objects.equals(payment.getPaymentMethod(), normalizePaymentMethod(expectedMethod))) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "支付通道与支付单不匹配");
        }
    }

    private void assertPaymentNotExpired(Payment payment) {
        if (payment.getExpiredAt() != null && payment.getExpiredAt().isBefore(LocalDateTime.now())) {
            String fromStatus = payment.getStatus();
            payment.setStatus("EXPIRED");
            paymentRepository.save(payment);
            recordLog(payment.getId(), payment.getPaymentNo(), null, null, "EXPIRE",
                    fromStatus, "EXPIRED", null, null, "支付超时自动过期");
            throw new BusinessException(ErrorCode.PAYMENT_EXPIRED);
        }
    }

    private String normalizePaymentMethod(String paymentMethod) {
        return paymentMethod == null ? "" : paymentMethod.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeCurrency(String currency) {
        return currency == null || currency.isBlank() ? "USD" : currency.trim().toUpperCase(Locale.ROOT);
    }

    private RefundResponse toRefundResponse(Refund refund) {
        return RefundResponse.builder()
                .id(refund.getId())
                .refundNo(refund.getRefundNo())
                .paymentId(refund.getPaymentId())
                .paymentNo(refund.getPaymentNo())
                .orderId(refund.getOrderId())
                .orderNo(refund.getOrderNo())
                .applicantId(refund.getApplicantId())
                .applicantName(refund.getApplicantName())
                .refundAmount(refund.getRefundAmount())
                .refundReason(refund.getRefundReason())
                .refundType(refund.getRefundType())
                .status(refund.getStatus())
                .auditorId(refund.getAuditorId())
                .auditorName(refund.getAuditorName())
                .auditRemark(refund.getAuditRemark())
                .auditedAt(refund.getAuditedAt())
                .transactionId(refund.getTransactionId())
                .refundedAt(refund.getRefundedAt())
                .createdAt(refund.getCreatedAt())
                .build();
    }
}
