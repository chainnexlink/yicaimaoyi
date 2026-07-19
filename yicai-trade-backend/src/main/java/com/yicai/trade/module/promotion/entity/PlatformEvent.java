package com.yicai.trade.module.promotion.entity;

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
@Table(name = "t_platform_event")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class PlatformEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "event_name", length = 200)
    private String eventName;

    @Column(name = "event_type", length = 30)
    private String eventType; // TRADE_FAIR, FLASH_SALE, GROUP_BUY, SEASONAL

    @Column(name = "description", length = 2000)
    private String description;

    @Column(name = "banner_url", length = 500)
    private String bannerUrl;

    @Column(name = "rules", length = 3000)
    private String rules;

    @Column(name = "max_participants")
    private Integer maxParticipants;

    @Column(name = "current_participants")
    @Builder.Default
    private Integer currentParticipants = 0;

    @Column(name = "signup_start")
    private LocalDateTime signupStart;

    @Column(name = "signup_end")
    private LocalDateTime signupEnd;

    @Column(name = "event_start")
    private LocalDateTime eventStart;

    @Column(name = "event_end")
    private LocalDateTime eventEnd;

    @Column(length = 20)
    @Builder.Default
    private String status = "DRAFT"; // DRAFT, SIGNUP_OPEN, SIGNUP_CLOSED, ACTIVE, ENDED

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
