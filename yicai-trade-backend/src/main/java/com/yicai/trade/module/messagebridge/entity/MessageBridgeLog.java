package com.yicai.trade.module.messagebridge.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_message_bridge_log")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class MessageBridgeLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "message_id")
    private Long messageId;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "channel_type", nullable = false, length = 20)
    private String channelType;  // WECHAT_WORK / QQ_BOT

    @Column(nullable = false, length = 10)
    private String direction;  // OUTBOUND / INBOUND

    @Column(name = "content_summary", length = 500)
    private String contentSummary;

    @Column(name = "external_msg_id", length = 100)
    private String externalMsgId;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "PENDING";  // PENDING / SUCCESS / FAILED

    @Column(name = "error_message", length = 1000)
    private String errorMessage;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
