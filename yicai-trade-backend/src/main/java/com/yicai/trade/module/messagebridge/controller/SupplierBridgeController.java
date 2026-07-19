package com.yicai.trade.module.messagebridge.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.messagebridge.dto.*;
import com.yicai.trade.module.messagebridge.repository.BridgeConfigRepository;
import com.yicai.trade.module.messagebridge.service.BridgeBindingService;
import com.yicai.trade.module.messagebridge.service.BridgeForwardingService;
import com.yicai.trade.module.messagebridge.service.BridgeSubscriptionService;
import com.yicai.trade.module.supplier.entity.Supplier;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/supplier/bridge")
@RequiredArgsConstructor
public class SupplierBridgeController {

    private final BridgeSubscriptionService subscriptionService;
    private final BridgeBindingService bindingService;
    private final BridgeForwardingService forwardingService;
    private final BridgeConfigRepository configRepository;
    private final SupplierRepository supplierRepository;

    @GetMapping("/status")
    public Result<?> getStatus(@RequestParam Long userId) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("供应商不存在"));
        return Result.success(subscriptionService.getSupplierStatus(supplier.getId()));
    }

    @GetMapping("/config")
    public Result<?> getConfig() {
        boolean enabled = configRepository.findByConfigKey("BRIDGE_SERVICE_ENABLED")
                .map(c -> "true".equalsIgnoreCase(c.getConfigValue())).orElse(false);
        BigDecimal price = configRepository.findByConfigKey("BRIDGE_MONTHLY_PRICE")
                .map(c -> new BigDecimal(c.getConfigValue())).orElse(new BigDecimal("99.00"));
        int trialDays = configRepository.findByConfigKey("BRIDGE_TRIAL_DAYS")
                .map(c -> Integer.parseInt(c.getConfigValue())).orElse(7);
        int maxForward = configRepository.findByConfigKey("BRIDGE_MAX_FORWARD_PER_DAY")
                .map(c -> Integer.parseInt(c.getConfigValue())).orElse(500);
        return Result.success(BridgeConfigResponse.builder()
                .serviceEnabled(enabled).monthlyPrice(price)
                .trialDays(trialDays).maxForwardPerDay(maxForward).build());
    }

    @PostMapping("/subscribe")
    public Result<?> subscribe(@RequestParam Long userId, @Valid @RequestBody BridgeSubscriptionRequest request) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("供应商不存在"));
        return Result.success(subscriptionService.subscribe(userId, supplier.getId(), request));
    }

    @PostMapping("/subscribe/{id}/cancel")
    public Result<?> cancelSubscription(@PathVariable Long id, @RequestParam Long userId) {
        subscriptionService.cancelSubscription(id, userId);
        return Result.success("订阅已取消");
    }

    @GetMapping("/subscriptions")
    public Result<?> listSubscriptions(@RequestParam Long userId,
                                            @RequestParam(defaultValue = "0") int page,
                                            @RequestParam(defaultValue = "10") int size) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("供应商不存在"));
        return Result.success(subscriptionService.listSupplierSubscriptions(supplier.getId(), page, size));
    }

    @PostMapping("/bind")
    public Result<?> bind(@RequestParam Long userId, @Valid @RequestBody BridgeBindingRequest request) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("供应商不存在"));
        return Result.success(bindingService.bind(userId, supplier.getId(), request));
    }

    @PostMapping("/bind/verify")
    public Result<?> verifyBinding(@RequestParam Long userId,
                                        @RequestParam String channelType,
                                        @RequestParam String code) {
        return Result.success(bindingService.verify(userId, channelType, code));
    }

    @DeleteMapping("/bind/{channelType}")
    public Result<?> unbind(@PathVariable String channelType, @RequestParam Long userId) {
        bindingService.unbind(userId, channelType);
        return Result.success("已解绑");
    }

    @GetMapping("/bindings")
    public Result<?> getBindings(@RequestParam Long userId) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("供应商不存在"));
        return Result.success(bindingService.getBindings(supplier.getId()));
    }

    @GetMapping("/logs")
    public Result<?> getLogs(@RequestParam Long userId,
                                  @RequestParam(defaultValue = "0") int page,
                                  @RequestParam(defaultValue = "10") int size) {
        Supplier supplier = supplierRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("供应商不存在"));
        return Result.success(forwardingService.getSupplierLogs(supplier.getId(), page, size));
    }
}
