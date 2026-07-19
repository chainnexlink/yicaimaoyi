package com.yicai.trade.module.thirdparty.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.thirdparty.dto.ThirdPartyConfigResponse;
import com.yicai.trade.module.thirdparty.dto.ThirdPartyConfigUpdateRequest;
import com.yicai.trade.module.thirdparty.dto.ThirdPartyLogResponse;
import com.yicai.trade.module.thirdparty.entity.ThirdPartyConfig;
import com.yicai.trade.module.thirdparty.entity.ThirdPartyLog;
import com.yicai.trade.module.thirdparty.repository.ThirdPartyConfigRepository;
import com.yicai.trade.module.thirdparty.repository.ThirdPartyLogRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/third-party")
@RequiredArgsConstructor
@Tag(name = "第三方接口管理", description = "管理所有第三方API配置、查看调用日志和用量统计")
public class ThirdPartyConfigController {

    private final ThirdPartyConfigRepository configRepository;
    private final ThirdPartyLogRepository logRepository;

    @GetMapping("/configs")
    @Operation(summary = "获取所有第三方接口配置")
    public Result<List<ThirdPartyConfigResponse>> listConfigs() {
        List<ThirdPartyConfigResponse> list = configRepository.findAllByOrderByIdAsc()
                .stream().map(this::toConfigResponse).collect(Collectors.toList());
        return Result.success(list);
    }

    @GetMapping("/configs/{id}")
    @Operation(summary = "获取单个接口配置详情")
    public Result<ThirdPartyConfigResponse> getConfig(@PathVariable Long id) {
        ThirdPartyConfig config = configRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("配置不存在: " + id));
        return Result.success(toConfigResponse(config));
    }

    @PutMapping("/configs/{id}")
    @Operation(summary = "更新接口配置")
    public Result<ThirdPartyConfigResponse> updateConfig(
            @PathVariable Long id, @RequestBody ThirdPartyConfigUpdateRequest request) {
        ThirdPartyConfig config = configRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("配置不存在: " + id));

        if (request.getApiUrl() != null) config.setApiUrl(request.getApiUrl());
        if (request.getAppKey() != null) config.setAppKey(request.getAppKey());
        if (request.getAppSecret() != null) config.setAppSecret(request.getAppSecret());
        if (request.getAppCode() != null) config.setAppCode(request.getAppCode());
        if (request.getExtraConfig() != null) config.setExtraConfig(request.getExtraConfig());
        if (request.getEnabled() != null) config.setEnabled(request.getEnabled());
        if (request.getTotalQuota() != null) config.setTotalQuota(request.getTotalQuota());
        if (request.getExpiresAt() != null) config.setExpiresAt(request.getExpiresAt());
        if (request.getRemark() != null) config.setRemark(request.getRemark());

        return Result.success(toConfigResponse(configRepository.save(config)));
    }

    @PatchMapping("/configs/{id}/toggle")
    @Operation(summary = "启用/禁用接口")
    public Result<Void> toggleConfig(@PathVariable Long id) {
        ThirdPartyConfig config = configRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("配置不存在: " + id));
        config.setEnabled(!config.getEnabled());
        configRepository.save(config);
        return Result.success(null);
    }

    @GetMapping("/logs")
    @Operation(summary = "查询接口调用日志")
    public Result<PageResult<ThirdPartyLogResponse>> listLogs(
            @RequestParam(required = false) String configKey,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<ThirdPartyLog> p = (configKey != null && !configKey.isEmpty())
                ? logRepository.findByConfigKey(configKey, pageable)
                : logRepository.findAll(pageable);

        List<ThirdPartyLogResponse> list = p.getContent().stream().map(this::toLogResponse).collect(Collectors.toList());
        return Result.success(PageResult.of(list, p.getTotalElements(), page, size));
    }

    @GetMapping("/stats")
    @Operation(summary = "接口用量统计")
    public Result<List<Map<String, Object>>> stats() {
        List<Map<String, Object>> stats = configRepository.findAllByOrderByIdAsc().stream().map(config -> {
            Map<String, Object> map = new HashMap<>();
            map.put("configKey", config.getConfigKey());
            map.put("configName", config.getConfigName());
            map.put("provider", config.getProvider());
            map.put("enabled", config.getEnabled());
            map.put("totalQuota", config.getTotalQuota());
            map.put("usedQuota", config.getUsedQuota());
            map.put("remainQuota", config.getTotalQuota() - config.getUsedQuota());
            map.put("expiresAt", config.getExpiresAt());
            map.put("successCount", logRepository.countByConfigKeyAndSuccess(config.getConfigKey(), true));
            map.put("failCount", logRepository.countByConfigKeyAndSuccess(config.getConfigKey(), false));
            return map;
        }).collect(Collectors.toList());
        return Result.success(stats);
    }

    private ThirdPartyConfigResponse toConfigResponse(ThirdPartyConfig c) {
        ThirdPartyConfigResponse r = new ThirdPartyConfigResponse();
        r.setId(c.getId());
        r.setConfigKey(c.getConfigKey());
        r.setConfigName(c.getConfigName());
        r.setProvider(c.getProvider());
        r.setApiUrl(c.getApiUrl());
        // 脱敏处理：只显示前6位+后4位
        r.setAppCode(maskSecret(c.getAppCode()));
        r.setAppKey(maskSecret(c.getAppKey()));
        r.setEnabled(c.getEnabled());
        r.setTotalQuota(c.getTotalQuota());
        r.setUsedQuota(c.getUsedQuota());
        r.setExpiresAt(c.getExpiresAt());
        r.setExtraConfig(c.getExtraConfig());
        r.setRemark(c.getRemark());
        r.setCreatedAt(c.getCreatedAt());
        r.setUpdatedAt(c.getUpdatedAt());
        return r;
    }

    private ThirdPartyLogResponse toLogResponse(ThirdPartyLog l) {
        ThirdPartyLogResponse r = new ThirdPartyLogResponse();
        r.setId(l.getId());
        r.setConfigKey(l.getConfigKey());
        r.setAction(l.getAction());
        r.setTarget(l.getTarget());
        r.setSuccess(l.getSuccess());
        r.setErrorMsg(l.getErrorMsg());
        r.setCostMs(l.getCostMs());
        r.setCreatedAt(l.getCreatedAt());
        return r;
    }

    private String maskSecret(String secret) {
        if (secret == null || secret.length() < 10) return secret;
        return secret.substring(0, 6) + "****" + secret.substring(secret.length() - 4);
    }
}
