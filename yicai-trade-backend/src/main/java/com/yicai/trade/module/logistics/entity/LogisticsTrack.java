package com.yicai.trade.module.logistics.entity;

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
@Table(name = "t_logistics_track")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class LogisticsTrack {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "logistics_id", nullable = false)
    private Long logisticsId;

    @Column(name = "tracking_no", length = 50)
    private String trackingNo;

    @Column(name = "node_time", nullable = false)
    private LocalDateTime nodeTime;

    @Column(length = 200)
    private String location;

    @Column(length = 50)
    private String status;

    @Column(length = 500)
    private String description;

    @Column(length = 100)
    private String operator;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
