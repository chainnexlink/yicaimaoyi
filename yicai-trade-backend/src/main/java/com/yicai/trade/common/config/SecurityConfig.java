package com.yicai.trade.common.config;

import com.yicai.trade.common.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final UserDetailsService userDetailsService;
    
    @Value("${spring.profiles.active:h2}")
    private String activeProfile;
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        boolean isProd = Arrays.stream(activeProfile.split(","))
                .map(String::trim)
                .anyMatch("prod"::equalsIgnoreCase);
        
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(Customizer.withDefaults())
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            );
        
        http.authorizeHttpRequests(auth -> {
            auth.requestMatchers("/", "/*.html", "/*.css", "/*.js", "/*.ico", "/*.png", "/*.jpg", "/*.jpeg", "/*.svg", "/*.woff2", "/assets/**", "/images/**", "/css/**", "/js/**", "/pages/**", "/forms/**", "/vibe_images/**").permitAll()
                .requestMatchers("/api/auth/**", "/api/public/**", "/actuator/health", "/ws/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/admin/content/banners/active", "/api/admin/content/news", "/api/admin/content/news/{id}").permitAll()
                .requestMatchers("/api/news/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/auction/list", "/api/v1/auction/home", "/api/v1/auction/{id}", "/api/v1/auction/{id}/bids", "/api/v1/auction/{id}/price-curve").permitAll()
                .requestMatchers("/api/payments/callback/**", "/api/webhook/**").permitAll()
                .requestMatchers("/api/v1/auction/admin/**", "/api/v1/auction/deposit/admin/**", "/api/escrow/admin/**", "/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/supplier/**").hasAnyRole("SUPPLIER", "ADMIN")
                .requestMatchers("/api/buyer/**").hasAnyRole("BUYER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/shop", "/api/shop/{id}").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/review/supplier/{supplierId}", "/api/review/supplier/{supplierId}/summary").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/supplier-credit/supplier/{supplierId}", "/api/supplier-credit/ranking").permitAll();

            if (!isProd) {
                auth.requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**", "/api-docs/**", "/h2-console/**").permitAll();
            }

            auth.anyRequest().authenticated();
        });
        
        http
            .headers(headers -> {
                headers.frameOptions(frame -> frame.sameOrigin());
                if (isProd) {
                    headers.contentSecurityPolicy(csp -> 
                        csp.policyDirectives("default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'")
                    );
                }
            })
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }
    
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
