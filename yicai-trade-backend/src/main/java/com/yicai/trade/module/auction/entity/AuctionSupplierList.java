package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 供应商黑白名单
 * 采购商管理供应商黑名单（禁止参与）和白名单（优先邀请）
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_supplier_list", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"buyer_id", "supplier_id", "list_type"})
})
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionSupplierList {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 采购商ID（名单所有者） */
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    /** 供应商ID */
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 供应商公司名称 */
    @Column(name = "supplier_company", length = 200)
    private String supplierCompany;

    /** 名单类型: WHITELIST(白名单) / BLACKLIST(黑名单) */
    @Column(name = "list_type", nullable = false, length = 20)
    private String listType;

    /** 加入原因 */
    @Column(name = "reason", length = 500)
    private String reason;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
