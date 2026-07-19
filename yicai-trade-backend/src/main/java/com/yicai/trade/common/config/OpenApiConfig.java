package com.yicai.trade.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.Components;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("易采贸易平台 - 后台接口文档")
                        .description("易采贸易平台后端API接口，包含用户认证、供应商管理、采购商管理、订单管理、智能匹配、询价报价、消息通知、实时聊天等模块。")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("易采贸易技术团队")
                                .email("support@yicai-trade.com")))
                .addSecurityItem(new SecurityRequirement().addList("Bearer认证"))
                .components(new Components()
                        .addSecuritySchemes("Bearer认证", new SecurityScheme()
                                .name("Authorization")
                                .description("JWT令牌认证，格式：Bearer {token}")
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }
}
