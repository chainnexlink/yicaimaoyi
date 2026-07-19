package com.yicai.trade.module.dashboard.service.impl;

import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.dashboard.dto.DashboardStats;
import com.yicai.trade.module.dashboard.service.DashboardService;
import com.yicai.trade.module.inquiry.repository.InquiryRepository;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final UserRepository userRepository;
    private final SupplierRepository supplierRepository;
    private final BuyerRepository buyerRepository;
    private final OrderRepository orderRepository;
    private final InquiryRepository inquiryRepository;
    private final ContractRepository contractRepository;

    @Override
    public DashboardStats getStats() {
        return DashboardStats.builder()
                .totalUsers(userRepository.count())
                .totalSuppliers(supplierRepository.count())
                .approvedSuppliers(supplierRepository.countByStatus("APPROVED"))
                .pendingSuppliers(supplierRepository.countByStatus("PENDING"))
                .totalBuyers(buyerRepository.count())
                .totalOrders(orderRepository.count())
                .pendingOrders(orderRepository.countByStatus("PENDING"))
                .completedOrders(orderRepository.countByStatus("COMPLETED"))
                .totalInquiries(inquiryRepository.count())
                .openInquiries(inquiryRepository.countByStatus("OPEN"))
                .totalContracts(contractRepository.count())
                .draftContracts(contractRepository.countByStatus("DRAFT"))
                .signedContracts(contractRepository.countByStatus("SIGNED"))
                .executingContracts(contractRepository.countByStatus("EXECUTING"))
                .completedContracts(contractRepository.countByStatus("COMPLETED"))
                .build();
    }
}
