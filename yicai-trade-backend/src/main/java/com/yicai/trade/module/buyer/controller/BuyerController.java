package com.yicai.trade.module.buyer.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.buyer.dto.BuyerProfileRequest;
import com.yicai.trade.module.buyer.dto.BuyerResponse;
import com.yicai.trade.module.buyer.entity.BuyerFavorite;
import com.yicai.trade.module.buyer.service.BuyerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/buyer")
@RequiredArgsConstructor
@Tag(name = "BuyerCenter")
public class BuyerController {

    private final BuyerService buyerService;

    @GetMapping("/profile")
    @Operation(summary = "Get buyer profile")
    public Result<BuyerResponse> getProfile(@AuthenticationPrincipal UserDetails user) {
        return Result.success(buyerService.getOrCreateBuyer(Long.parseLong(user.getUsername())));
    }

    @PutMapping("/profile")
    @Operation(summary = "Update buyer profile")
    public Result<BuyerResponse> updateProfile(@AuthenticationPrincipal UserDetails user,
                                               @RequestBody BuyerProfileRequest request) {
        return Result.success(buyerService.updateProfile(Long.parseLong(user.getUsername()), request));
    }

    @PostMapping("/favorites")
    @Operation(summary = "Add favorite")
    public Result<Void> addFavorite(@RequestBody Map<String, Object> body) {
        buyerService.addFavorite(
                Long.parseLong(body.get("buyerId").toString()),
                Long.parseLong(body.get("productId").toString()),
                body.get("supplierId") != null ? Long.parseLong(body.get("supplierId").toString()) : null,
                (String) body.get("type"));
        return Result.success();
    }

    @DeleteMapping("/favorites")
    @Operation(summary = "Remove favorite")
    public Result<Void> removeFavorite(@RequestParam Long buyerId, @RequestParam Long productId) {
        buyerService.removeFavorite(buyerId, productId);
        return Result.success();
    }

    @GetMapping("/favorites")
    @Operation(summary = "List favorites")
    public Result<PageResult<BuyerFavorite>> listFavorites(
            @RequestParam Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(buyerService.listFavorites(buyerId, page, size));
    }

    @GetMapping("/favorites/check")
    @Operation(summary = "Check favorite")
    public Result<Boolean> isFavorite(@RequestParam Long buyerId, @RequestParam Long productId) {
        return Result.success(buyerService.isFavorite(buyerId, productId));
    }
}
