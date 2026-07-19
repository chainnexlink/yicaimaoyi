package com.yicai.trade.module.messagebridge.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_message_bridge_binding")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class MessageBridgeBinding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "channel_type", nullable = false, length = 20)
    private String channelType;  // WECHAT_WORK / QQ_BOT

    @Column(name = "channel_user_id", length = 100)
    private String channelUserId;

    @Column(name = "channel_username", length = 100)
    private String channelUsername;

    @Column(name = "bind_status", nullable = false, length = 20)
    @Builder.Default
    private String bindStatus = "UNBOUND";  // UNBOUND / PENDING / BOUND / REVOKED

    @Column(name = "verification_code", length = 20)
    private String verificationCode;

    @Column(name = "verification_expire")
    private LocalDateTime verificationExpire;

    @Column(name = "bound_at")
    private LocalDateTime boundAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
