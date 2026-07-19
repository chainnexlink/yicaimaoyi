package com.yicai.trade.module.buyer.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.buyer.entity.Buyer;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/admin/buyers")
@RequiredArgsConstructor
@Tag(name = "AdminBuyer")
public class AdminBuyerController {

    private final BuyerRepository buyerRepository;
    private final UserRepository userRepository;

    @GetMapping
    @Operation(summary = "list buyers with user info")
    public Result<PageResult<Map<String, Object>>> listBuyers(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Page<Buyer> buyers = buyerRepository.search(keyword,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        
        List<Map<String, Object>> list = new ArrayList<>();
        for (Buyer b : buyers.getContent()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", b.getId());
            item.put("userId", b.getUserId());
            item.put("companyName", b.getCompanyName());
            item.put("contactPerson", b.getContactPerson());
            item.put("contactPhone", b.getContactPhone());
            item.put("address", b.getAddress());
            item.put("industry", b.getIndustry());
            item.put("createdAt", b.getCreatedAt());
            
            // 关联 User 信息
            if (b.getUserId() != null) {
                userRepository.findById(b.getUserId()).ifPresent(user -> {
                    item.put("username", user.getUsername());
                    item.put("email", user.getEmail());
                    item.put("phone", user.getPhone());
                    item.put("userStatus", user.getStatus());
                    item.put("userType", user.getUserType());
                    item.put("registerTime", user.getCreatedAt());
                });
            }
            list.add(item);
        }
        
        return Result.success(PageResult.of(list, buyers.getTotalElements(), page, size));
    }
}
