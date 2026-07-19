package com.yicai.trade.module.dispute.entity;

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
@Table(name = "t_dispute_message")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class DisputeMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "dispute_id")
    private Long disputeId;

    @Column(name = "sender_id")
    private Long senderId;

    @Column(name = "sender_role", length = 20)
    private String senderRole; // BUYER, SUPPLIER, PLATFORM

    @Column(name = "content", length = 2000)
    private String content;

    @Column(name = "attachment_urls", length = 2000)
    private String attachmentUrls;

    @Column(name = "msg_type", length = 20)
    @Builder.Default
    private String msgType = "TEXT"; // TEXT, EVIDENCE, RULING, SYSTEM

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
