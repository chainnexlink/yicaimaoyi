package com.yicai.trade.module.smartmatch.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.smartmatch.dto.*;
import com.yicai.trade.module.smartmatch.service.SmartMatchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Smart Match", description = "AI智能匹配API")
@RestController
@RequestMapping("/api/v1/smart-match")
@RequiredArgsConstructor
public class SmartMatchController {

    private final SmartMatchService smartMatchService;

    @Operation(summary = "品类匹配", description = "根据产品名称匹配品类列表")
    @PostMapping("/categories")
    public Result<CategoryMatchResponse> matchCategories(
            @RequestParam("productName") String productName,
            @RequestParam(value = "imageUrl", required = false) String imageUrl,
            @RequestParam(value = "lang", defaultValue = "zh") String lang) {
        CategoryMatchResponse response = smartMatchService.matchCategories(productName, imageUrl, lang);
        return Result.success(response);
    }

    @Operation(summary = "获取成本参数", description = "获取品类的成本预估参数列表")
    @PostMapping("/parameters/cost")
    public Result<ParameterResponse> getCostParameters(@RequestBody ParameterRequest request) {
        ParameterResponse response = smartMatchService.getCostParameters(request, request.getLang());
        return Result.success(response);
    }

    @Operation(summary = "获取FOB参数", description = "获取FOB价格预估参数列表")
    @PostMapping("/parameters/fob")
    public Result<ParameterResponse> getFOBParameters(@RequestBody ParameterRequest request) {
        ParameterResponse response = smartMatchService.getFOBParameters(request, request.getLang());
        return Result.success(response);
    }

    @Operation(summary = "成本预估", description = "计算成本并生成供应商列表")
    @PostMapping("/estimate/cost")
    public Result<CostEstimateResponse> estimateCost(@RequestBody CostEstimateRequest request) {
        CostEstimateResponse response = smartMatchService.estimateCost(request, request.getLang());
        return Result.success(response);
    }

    @Operation(summary = "FOB预估", description = "计算FOB价格(含国内运费)")
    @PostMapping("/estimate/fob")
    public Result<FOBEstimateResponse> estimateFOB(@RequestBody FOBEstimateRequest request) {
        FOBEstimateResponse response = smartMatchService.estimateFOB(request, request.getLang());
        return Result.success(response);
    }

    @Operation(summary = "工厂预估报价", description = "基于成本和行业利润率计算工厂报价区间")
    @PostMapping("/estimate/factory-quote")
    public Result<FactoryQuoteResponse> estimateFactoryQuote(
            @RequestParam("sessionId") String sessionId,
            @RequestParam("categoryCode") String categoryCode,
            @RequestParam(value = "lang", defaultValue = "zh") String lang) {
        FactoryQuoteResponse response = smartMatchService.estimateFactoryQuote(sessionId, categoryCode, lang);
        return Result.success(response);
    }
}
