package com.yicai.trade.module.auction.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface AuctionDepositService {

    // ========== 押金操作 ==========

    /** 采购商缴纳发布押金 */
    Map<String, Object> payBuyerDeposit(Long auctionId, Long buyerId, Long voucherId);

    /** 供应商缴纳竞拍押金 */
    Map<String, Object> paySupplierDeposit(Long auctionId, Long supplierId, Long voucherId);

    /** 退还押金 */
    void refundDeposit(Long depositId, String reason);

    /** 批量退还拍卖的所有押金 */
    void refundAllDeposits(Long auctionId, String reason);

    /** 没收押金 */
    void forfeitDeposit(Long depositId, String reason);

    /** 检查用户是否已缴纳押金 */
    boolean hasValidDeposit(Long auctionId, Long userId);

    // ========== 抵用券操作 ==========

    /** 发放注册抵用券 */
    void issueRegisterVouchers(Long userId, String userType);

    /** 管理员发放抵用券 */
    void adminIssueVouchers(Long userId, String userType, int count, BigDecimal faceValue, Long adminId, String remark);

    /** 获取用户可用抵用券 */
    List<Map<String, Object>> getUserVouchers(Long userId, String voucherType);

    /** 撤销抵用券 */
    void revokeVoucher(Long voucherId, Long adminId);

    // ========== 配置操作 ==========

    /** 获取所有押金配置 */
    List<Map<String, Object>> getAllConfig();

    /** 更新配置 */
    void updateConfig(String key, String value, Long adminId);

    /** 获取采购商押金金额 */
    BigDecimal getBuyerDepositAmount();

    /** 获取供应商押金金额 */
    BigDecimal getSupplierDepositAmount();

    // ========== 统计 ==========

    Map<String, Object> getDepositStats();

    /** 获取押金记录列表 */
    List<Map<String, Object>> getDepositRecords(String status);

    // ========== 自动退还 ==========

    void autoRefundCompletedAuctions();
}
