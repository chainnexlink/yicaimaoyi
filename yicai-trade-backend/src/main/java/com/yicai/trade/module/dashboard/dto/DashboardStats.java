package com.yicai.trade.module.dashboard.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(name = "DashboardStats")
public class DashboardStats {
    private long totalUsers;
    private long totalSuppliers;
    private long approvedSuppliers;
    private long pendingSuppliers;
    private long totalBuyers;
    private long totalOrders;
    private long pendingOrders;
    private long completedOrders;
    private long totalInquiries;
    private long openInquiries;
    // 合同统计
    private long totalContracts;
    private long draftContracts;
    private long signedContracts;
    private long executingContracts;
    private long completedContracts;
}
