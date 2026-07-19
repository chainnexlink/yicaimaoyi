package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 拍卖出价记录
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_bid")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionBid {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 所属拍卖 */
    @NonNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "auction_id", nullable = false)
    private Auction auction;

    /** 出价供应商ID */
    @NonNull
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 供应商公司名称 */
    @Column(name = "supplier_company", length = 200)
    private String supplierCompany;

    /** 出价金额(单价) */
    @NonNull
    @Column(name = "bid_price", nullable = false, precision = 16, scale = 4)
    private BigDecimal bidPrice;

    /** 出价序号(第几次出价) */
    @Column(name = "bid_sequence")
    private Integer bidSequence;

    /** 是否当前最低价 */
    @Column(name = "is_lowest")
    @Builder.Default
    private Boolean isLowest = false;

    /** 是否中标 */
    @Column(name = "is_winner")
    @Builder.Default
    private Boolean isWinner = false;

    /** 供应商备注 */
    @Column(name = "remark", length = 500)
    private String remark;

    /** 出价IP地址(安全审计) */
    @Column(name = "bid_ip", length = 50)
    private String bidIp;

    /** 出价总额（单价*数量） */
    @Column(name = "total_amount", precision = 18, scale = 4)
    private BigDecimal totalAmount;

    /** 承诺交货天数 */
    @Column(name = "promised_delivery_days")
    private Integer promisedDeliveryDays;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
