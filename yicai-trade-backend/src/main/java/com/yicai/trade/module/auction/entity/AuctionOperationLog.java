package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 拍卖操作日志（不可修改删除）
 * 全链路留痕：创建、审核、出价、报名、结束、确认等所有操作
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_operation_log")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionOperationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 拍卖ID */
    @Column(name = "auction_id", nullable = false)
    private Long auctionId;

    /** 拍卖编号 */
    @Column(name = "auction_no", length = 50)
    private String auctionNo;

    /**
     * 操作类型
     * CREATE/PUBLISH/APPROVE/REJECT/CANCEL/START/END/BID/SIGNUP/
     * CONFIRM/EXTEND/FAIL/EXPORT/REAUCTION/VOID/INVITE/SCORE
     */
    @Column(name = "operation_type", nullable = false, length = 30)
    private String operationType;

    /** 操作前状态 */
    @Column(name = "from_status", length = 20)
    private String fromStatus;

    /** 操作后状态 */
    @Column(name = "to_status", length = 20)
    private String toStatus;

    /** 操作人ID */
    @Column(name = "operator_id")
    private Long operatorId;

    /** 操作人名称 */
    @Column(name = "operator_name", length = 100)
    private String operatorName;

    /** 操作详情 */
    @Column(name = "detail", length = 2000)
    private String detail;

    /** 操作IP */
    @Column(name = "ip_address", length = 50)
    private String ipAddress;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
