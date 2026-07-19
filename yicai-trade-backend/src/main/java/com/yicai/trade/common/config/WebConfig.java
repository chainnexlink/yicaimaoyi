package com.yicai.trade.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 静态资源配置
 * 将前端HTML文件（项目根目录）映射为Spring Boot静态资源
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addRedirectViewController("/", "/index.html");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 仅暴露前端资源白名单，避免 pom.xml、配置文件、日志和构建产物被下载。
        registry.addResourceHandler(
                        "/*.html", "/*.css", "/*.js", "/*.ico", "/*.png", "/*.jpg", "/*.jpeg", "/*.svg", "/*.woff2",
                        "/assets/**", "/images/**", "/css/**", "/js/**", "/pages/**", "/forms/**", "/vibe_images/**")
                .addResourceLocations("file:../")
                .setCachePeriod(0);
    }
}
