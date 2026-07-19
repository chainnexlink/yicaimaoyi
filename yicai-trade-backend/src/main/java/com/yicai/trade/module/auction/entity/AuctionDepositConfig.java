package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 押金配置（系统级别）
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_deposit_config")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionDepositConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "config_key", nullable = false, unique = true, length = 50)
    private String configKey;

    @NonNull
    @Column(name = "config_value", nullable = false, length = 200)
    private String configValue;

    @Column(length = 500)
    private String description;

    @Column(name = "updated_by")
    private Long updatedBy;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
