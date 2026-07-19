package com.yicai.trade.module.wallet.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.wallet.dto.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface WalletService {

    // ===== 零钱钱包 =====

    /** 获取或创建钱包 */
    WalletResponse getOrCreateWallet(Long ownerId, String ownerType);

    /** 查询钱包余额 */
    WalletResponse getWallet(Long ownerId, String ownerType);

    /** 查询钱包流水 */
    PageResult<WalletTransactionResponse> getTransactions(Long ownerId, String ownerType, int page, int size);

    /** 充值 */
    WalletResponse recharge(Long ownerId, String ownerType, BigDecimal amount, String description);

    /** 提现 */
    WalletResponse withdraw(Long ownerId, String ownerType, BigDecimal amount, String description);

    // ===== 平台佣金 =====

    /** 创建佣金记录（客户通过API设置返佣比例） */
    CommissionResponse createCommission(Long buyerId, CommissionCreateRequest request);

    /** 确保合同存在佣金记录，如不存在则以默认返佣比例创建（内部服务调用） */
    CommissionResponse ensureCommission(Long contractId, BigDecimal defaultRebateRate);

    /** 收取服务费（合同开始执行时触发） */
    CommissionResponse collectServiceFee(Long contractId);

    /** 执行返佣（合同完成时触发，返佣金额入客户零钱） */
    CommissionResponse executeRebate(Long contractId);

    /** 查询合同关联的佣金信息 */
    CommissionResponse getCommissionByContract(Long contractId);

    /** 查询客户所有佣金记录 */
    List<CommissionResponse> listBuyerCommissions(Long buyerId);

    /** 后台分页查询所有佣金 */
    PageResult<CommissionResponse> listAllCommissions(int page, int size);

    /** 手动调整零钱余额（平台管理员） */
    WalletResponse adjustBalance(Long ownerId, String ownerType, BigDecimal amount, String reason, Long operatorId);

    // ===== 后台管理 =====

    /** 按角色列出所有钱包 */
    List<WalletResponse> listWalletsByType(String ownerType);

    /** 后台分页查询全部流水（支持按角色和类型过滤） */
    PageResult<WalletTransactionResponse> getAllTransactions(String ownerType, String transactionType, int page, int size);

    /** 后台统计汇总 */
    Map<String, Object> getWalletStats();

    /** 按状态分页查询佣金 */
    PageResult<CommissionResponse> listCommissionsByStatus(String status, int page, int size);

    /** 更新钱包状态（冻结/解冻/关闭） */
    WalletResponse updateWalletStatus(Long ownerId, String ownerType, String status, String reason, Long operatorId);
}
