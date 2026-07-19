package com.yicai.trade.module.payment.service;

import com.yicai.trade.module.payment.dto.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Map;
import java.math.BigDecimal;

public interface PaymentService {
    
    // 支付相关
    PaymentResponse createPayment(PaymentCreateRequest request, Long payerId);
    PaymentResponse getPaymentById(Long id);
    PaymentResponse getPaymentByNo(String paymentNo);
    List<PaymentResponse> getPaymentsByOrderId(Long orderId);
    Page<PaymentResponse> getPaymentsByPayer(Long payerId, Pageable pageable);
    Page<PaymentResponse> getPaymentsByPayee(Long payeeId, Pageable pageable);
    PaymentResponse confirmPayment(Long paymentId, String transactionId);
    PaymentResponse markPaymentProcessing(Long paymentId, String expectedMethod, String providerTransactionId);
    PaymentResponse confirmExternalPayment(Long paymentId, String expectedMethod,
                                           String providerTransactionId, BigDecimal confirmedAmount,
                                           String confirmedCurrency);
    PaymentResponse cancelPayment(Long paymentId, String reason);
    
    // 退款相关
    RefundResponse createRefund(RefundCreateRequest request, Long applicantId);
    RefundResponse getRefundById(Long id);
    RefundResponse getRefundByNo(String refundNo);
    List<RefundResponse> getRefundsByOrderId(Long orderId);
    Page<RefundResponse> getRefundsByApplicant(Long applicantId, Pageable pageable);
    Page<RefundResponse> getPendingRefunds(Pageable pageable);
    RefundResponse approveRefund(Long refundId, Long auditorId, String remark);
    RefundResponse rejectRefund(Long refundId, Long auditorId, String remark);
    RefundResponse processRefund(Long refundId, String transactionId);

    // 管理后台
    Page<PaymentResponse> getAllPayments(String status, Pageable pageable);
    Page<RefundResponse> getAllRefunds(String status, Pageable pageable);
    Map<String, Object> getPaymentStatistics();
}
