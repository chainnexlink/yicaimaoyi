package com.yicai.trade.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {
    
    @Value("${spring.profiles.active:h2}")
    private String activeProfile;
    
    @Value("${cors.allowed-origins:*}")
    private String allowedOrigins;
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        boolean isProd = Arrays.stream(activeProfile.split(","))
                .map(String::trim)
                .anyMatch("prod"::equalsIgnoreCase);
        if (isProd) {
            // 生产环境：限制CORS来源（通过环境变量配置）
            if ("*".equals(allowedOrigins)) {
                // 未显式配置时不开放跨域；同源请求不受 CORS 影响。
                configuration.setAllowedOrigins(List.of());
                configuration.setAllowCredentials(false);
            } else {
                configuration.setAllowedOrigins(Arrays.stream(allowedOrigins.split(","))
                        .map(String::trim).filter(origin -> !origin.isEmpty()).toList());
                configuration.setAllowCredentials(true);
            }
        } else {
            // 开发环境：允许所有来源
            configuration.setAllowedOriginPatterns(List.of("*"));
            configuration.setAllowCredentials(true);
        }
        
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setExposedHeaders(List.of("Authorization"));
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
