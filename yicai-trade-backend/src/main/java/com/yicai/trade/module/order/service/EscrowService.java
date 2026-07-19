package com.yicai.trade.module.order.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.order.dto.EscrowResponse;

public interface EscrowService {

    /** 创建托管记录（订单付款确认后自动触发） */
    EscrowResponse createEscrow(Long orderId);

    /** 查询订单的托管信息 */
    EscrowResponse getEscrowByOrderId(Long orderId);

    /** 释放托管资金到供应商（订单完成后触发） */
    EscrowResponse releaseEscrow(Long orderId);

    /** 采购商申请提前释放 */
    EscrowResponse requestEarlyRelease(Long orderId, Long buyerId, String reason);

    /** 管理员审批提前释放 */
    EscrowResponse approveEarlyRelease(Long escrowId, Long adminId, String remark);

    /** 管理员拒绝提前释放 */
    EscrowResponse rejectEarlyRelease(Long escrowId, Long adminId, String remark);

    /** 订单取消时退款托管资金 */
    EscrowResponse refundEscrow(Long orderId);

    /** 自动释放到期的托管资金（定时任务调用） */
    int autoReleaseExpiredEscrows();

    /** 后台查询托管列表（按状态） */
    PageResult<EscrowResponse> listEscrowsByStatus(String status, int page, int size);

    /** 查询采购商的托管列表 */
    PageResult<EscrowResponse> listBuyerEscrows(Long buyerId, int page, int size);

    /** 查询供应商的托管列表 */
    PageResult<EscrowResponse> listSupplierEscrows(Long supplierId, int page, int size);
}
