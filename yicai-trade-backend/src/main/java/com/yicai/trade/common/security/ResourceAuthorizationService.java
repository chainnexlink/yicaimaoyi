package com.yicai.trade.common.security;

import com.yicai.trade.module.auth.entity.User;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.payment.entity.Payment;
import com.yicai.trade.module.payment.entity.Refund;
import com.yicai.trade.module.payment.repository.PaymentRepository;
import com.yicai.trade.module.payment.repository.RefundRepository;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Objects;

@Component
@RequiredArgsConstructor
public class ResourceAuthorizationService {

    private final UserRepository userRepository;
    private final BuyerRepository buyerRepository;
    private final SupplierRepository supplierRepository;
    private final OrderRepository orderRepository;
    private final ContractRepository contractRepository;
    private final PaymentRepository paymentRepository;
    private final RefundRepository refundRepository;

    public void assertBuyerAccess(Long buyerId) {
        if (isAdmin()) return;
        Long userId = currentUserId();
        boolean allowed = buyerRepository.findById(buyerId)
                .map(buyer -> Objects.equals(buyer.getUserId(), userId))
                .orElse(false);
        denyUnless(allowed);
    }

    public void assertUserAccess(Long userId) {
        if (isAdmin()) return;
        denyUnless(Objects.equals(currentUserId(), userId));
    }

    public void assertPartyAccess(String partyType, Long partyId) {
        if ("BUYER".equalsIgnoreCase(partyType)) {
            assertBuyerAccess(partyId);
        } else if ("SUPPLIER".equalsIgnoreCase(partyType)) {
            assertSupplierAccess(partyId);
        } else {
            throw new AccessDeniedException("不支持的主体类型");
        }
    }

    public void assertContractPartyAccess(Long contractId, Long partyId) {
        if (isAdmin()) return;
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该合同"));
        if (Objects.equals(contract.getBuyerId(), partyId)) {
            assertBuyerAccess(partyId);
        } else if (Objects.equals(contract.getSupplierId(), partyId)) {
            assertSupplierAccess(partyId);
        } else {
            throw new AccessDeniedException("无权代表该合同主体");
        }
    }

    public void assertSupplierAccess(Long supplierId) {
        if (isAdmin()) return;
        Long userId = currentUserId();
        boolean allowed = supplierRepository.findById(supplierId)
                .map(supplier -> Objects.equals(supplier.getUserId(), userId))
                .orElse(false);
        denyUnless(allowed);
    }

    public void assertOrderAccess(Long orderId) {
        if (isAdmin()) return;
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该订单"));
        denyUnless(ownsBuyer(order.getBuyerId()) || ownsSupplier(order.getSupplierId()));
    }

    public void assertOrderBuyerAccess(Long orderId) {
        if (isAdmin()) return;
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该订单"));
        denyUnless(ownsBuyer(order.getBuyerId()));
    }

    public void assertOrderSupplierAccess(Long orderId) {
        if (isAdmin()) return;
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该订单"));
        denyUnless(ownsSupplier(order.getSupplierId()));
    }

    public void assertPaymentAccess(Long paymentId) {
        if (isAdmin()) return;
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该支付记录"));
        assertOrderAccess(payment.getOrderId());
    }

    public void assertPaymentPayerAccess(Long paymentId) {
        if (isAdmin()) return;
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该支付记录"));
        denyUnless(Objects.equals(payment.getPayerId(), currentUserId()));
    }

    public void assertPaymentNumberAccess(String paymentNo) {
        if (isAdmin()) return;
        Payment payment = paymentRepository.findByPaymentNo(paymentNo)
                .orElseThrow(() -> new AccessDeniedException("无权访问该支付记录"));
        assertOrderAccess(payment.getOrderId());
    }

    public void assertRefundAccess(Long refundId) {
        if (isAdmin()) return;
        Refund refund = refundRepository.findById(refundId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该退款记录"));
        assertOrderAccess(refund.getOrderId());
    }

    public void assertRefundNumberAccess(String refundNo) {
        if (isAdmin()) return;
        Refund refund = refundRepository.findByRefundNo(refundNo)
                .orElseThrow(() -> new AccessDeniedException("无权访问该退款记录"));
        assertOrderAccess(refund.getOrderId());
    }

    public void assertContractAccess(Long contractId) {
        if (isAdmin()) return;
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new AccessDeniedException("无权访问该合同"));
        denyUnless(ownsBuyer(contract.getBuyerId()) || ownsSupplier(contract.getSupplierId()));
    }

    public void assertContractNumberAccess(String contractNo) {
        if (isAdmin()) return;
        Contract contract = contractRepository.findByContractNo(contractNo)
                .orElseThrow(() -> new AccessDeniedException("无权访问该合同"));
        denyUnless(ownsBuyer(contract.getBuyerId()) || ownsSupplier(contract.getSupplierId()));
    }

    private boolean ownsBuyer(Long buyerId) {
        Long userId = currentUserId();
        return buyerRepository.findById(buyerId)
                .map(buyer -> Objects.equals(buyer.getUserId(), userId))
                .orElse(false);
    }

    private boolean ownsSupplier(Long supplierId) {
        Long userId = currentUserId();
        return supplierRepository.findById(supplierId)
                .map(supplier -> Objects.equals(supplier.getUserId(), userId))
                .orElse(false);
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new AccessDeniedException("请先登录");
        }
        String principal = authentication.getName();
        try {
            Long userId = Long.parseLong(principal);
            if (userRepository.existsById(userId)) {
                return userId;
            }
        } catch (NumberFormatException ignored) {
            // 兼容测试或非 JWT 认证中使用用户名作为 principal 的场景。
        }
        User user = userRepository.findByUsername(principal)
                .orElseThrow(() -> new AccessDeniedException("登录用户不存在"));
        return user.getId();
    }

    private boolean isAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()));
    }

    private void denyUnless(boolean allowed) {
        if (!allowed) {
            throw new AccessDeniedException("无权访问该资源");
        }
    }
}
