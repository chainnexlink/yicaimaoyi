package com.yicai.trade.module.thirdparty.entity;

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
@Table(name = "t_third_party_config")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class ThirdPartyConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "config_key", unique = true, nullable = false, length = 50)
    private String configKey;

    @Column(name = "config_name", nullable = false, length = 100)
    private String configName;

    @Column(length = 100)
    private String provider;

    @Column(name = "api_url", length = 500)
    private String apiUrl;

    @Column(name = "app_key", length = 200)
    private String appKey;

    @Column(name = "app_secret", length = 200)
    private String appSecret;

    @Column(name = "app_code", length = 200)
    private String appCode;

    @Column(name = "extra_config", columnDefinition = "TEXT")
    private String extraConfig;

    @Column
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "total_quota")
    @Builder.Default
    private Integer totalQuota = 0;

    @Column(name = "used_quota")
    @Builder.Default
    private Integer usedQuota = 0;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(length = 500)
    private String remark;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
