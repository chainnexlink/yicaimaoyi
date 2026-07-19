package com.yicai.trade.module.seooutlink.entity;

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
@Table(name = "t_seo_blog_binding",
        uniqueConstraints = @UniqueConstraint(columnNames = {"supplier_id", "platform"}))
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class SeoBlogBinding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 博客平台: WORDPRESS / BLOGGER / TUMBLR */
    @Column(nullable = false, length = 30)
    private String platform;

    @Column(name = "blog_url", nullable = false, length = 500)
    private String blogUrl;

    @Column(length = 200)
    private String username;

    /** 密码/应用密码(应加密存储，当前简易方案) */
    @Column(name = "app_password", length = 500)
    private String appPassword;

    @Column(name = "auto_publish", nullable = false)
    @Builder.Default
    private Boolean autoPublish = true;

    @Column(name = "daily_limit", nullable = false)
    @Builder.Default
    private Integer dailyLimit = 1;

    /** ACTIVE / DISABLED / ERROR */
    @Column(length = 20, nullable = false)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "last_test_at")
    private LocalDateTime lastTestAt;

    @Column(name = "last_test_ok")
    private Boolean lastTestOk;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
