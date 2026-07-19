package com.yicai.trade.module.comment.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.comment.dto.CommentResponse;
import com.yicai.trade.module.comment.service.CommentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/comments")
@RequiredArgsConstructor
@Tag(name = "评论管理", description = "评论审核与管理接口")
public class CommentController {

    private final CommentService commentService;

    @GetMapping
    @Operation(summary = "分页查询评论列表")
    public Result<PageResult<CommentResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String sourceType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(commentService.list(status, sourceType, page, size));
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "通过评论")
    public Result<Void> approve(@PathVariable Long id) {
        commentService.approve(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/hide")
    @Operation(summary = "隐藏评论")
    public Result<Void> hide(@PathVariable Long id) {
        commentService.hide(id);
        return Result.success(null);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除评论")
    public Result<Void> delete(@PathVariable Long id) {
        commentService.delete(id);
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "评论统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(commentService.getStats());
    }
}
