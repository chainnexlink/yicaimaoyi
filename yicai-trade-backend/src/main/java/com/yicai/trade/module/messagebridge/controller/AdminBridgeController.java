package com.yicai.trade.module.messagebridge.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeConfig;
import com.yicai.trade.module.messagebridge.repository.BridgeConfigRepository;
import com.yicai.trade.module.messagebridge.service.BridgeForwardingService;
import com.yicai.trade.module.messagebridge.service.BridgeSubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/bridge")
@RequiredArgsConstructor
public class AdminBridgeController {

    private final BridgeSubscriptionService subscriptionService;
    private final BridgeForwardingService forwardingService;
    private final BridgeConfigRepository configRepository;

    @GetMapping("/config")
    public Result<?> getConfig() {
        List<MessageBridgeConfig> configs = configRepository.findAllByOrderByIdAsc();
        return Result.success(configs);
    }

    @PutMapping("/config")
    public Result<?> updateConfig(@RequestBody Map<String, String> configMap) {
        for (Map.Entry<String, String> entry : configMap.entrySet()) {
            configRepository.findByConfigKey(entry.getKey()).ifPresent(config -> {
                config.setConfigValue(entry.getValue());
                configRepository.save(config);
            });
        }
        return Result.success("配置已更新");
    }

    @GetMapping("/subscriptions")
    public Result<?> listSubscriptions(@RequestParam(required = false) String status,
                                            @RequestParam(defaultValue = "0") int page,
                                            @RequestParam(defaultValue = "10") int size) {
        return Result.success(subscriptionService.listAllSubscriptions(status, page, size));
    }

    @PatchMapping("/subscriptions/{id}/status")
    public Result<?> updateSubscriptionStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        String newStatus = body.get("status");
        if ("ACTIVE".equals(newStatus)) {
            return Result.success(subscriptionService.activateSubscription(id));
        }
        // For other status changes, could add more logic
        return Result.success("状态已更新");
    }

    @GetMapping("/stats")
    public Result<?> getStats() {
        return Result.success(forwardingService.getStats());
    }

    @GetMapping("/logs")
    public Result<?> getLogs(@RequestParam(defaultValue = "0") int page,
                                  @RequestParam(defaultValue = "20") int size) {
        return Result.success(forwardingService.getAllLogs(page, size));
    }

    @PostMapping("/toggle-service")
    public Result<?> toggleService(@RequestBody Map<String, String> body) {
        String enabled = body.getOrDefault("enabled", "false");
        configRepository.findByConfigKey("BRIDGE_SERVICE_ENABLED").ifPresent(config -> {
            config.setConfigValue(enabled);
            configRepository.save(config);
        });
        return Result.success("服务状态已更新: " + enabled);
    }
}
