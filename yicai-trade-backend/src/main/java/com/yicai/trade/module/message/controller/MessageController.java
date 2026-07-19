package com.yicai.trade.module.message.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.message.dto.BroadcastRequest;
import com.yicai.trade.module.message.dto.MessageRequest;
import com.yicai.trade.module.message.dto.MessageResponse;
import com.yicai.trade.module.message.service.MessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/messages")
@RequiredArgsConstructor
@Tag(name = "消息管理", description = "系统消息管理接口")
public class MessageController {

    private final MessageService messageService;

    @PostMapping
    @Operation(summary = "发送消息")
    public Result<MessageResponse> sendMessage(@Valid @RequestBody MessageRequest request) {
        return Result.success(messageService.sendMessage(1L, request));
    }

    @PostMapping("/broadcast")
    @Operation(summary = "发送广播消息")
    public Result<Void> sendBroadcast(@Valid @RequestBody BroadcastRequest request) {
        messageService.sendBroadcast(1L, request);
        return Result.success(null);
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取消息详情")
    public Result<MessageResponse> getMessage(@PathVariable Long id) {
        return Result.success(messageService.getMessage(id));
    }

    @GetMapping
    @Operation(summary = "分页查询所有消息")
    public Result<PageResult<MessageResponse>> listAllMessages(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(messageService.listAllMessages(page, size));
    }

    @GetMapping("/type/{type}")
    @Operation(summary = "按类型查询消息")
    public Result<PageResult<MessageResponse>> listMessagesByType(
            @PathVariable String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(messageService.listMessagesByType(type, page, size));
    }

    @GetMapping("/user/{receiverId}")
    @Operation(summary = "查询用户消息")
    public Result<PageResult<MessageResponse>> listMessages(
            @PathVariable Long receiverId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(messageService.listMessages(receiverId, page, size));
    }

    @GetMapping("/user/{receiverId}/unread")
    @Operation(summary = "查询用户未读消息")
    public Result<PageResult<MessageResponse>> listUnreadMessages(
            @PathVariable Long receiverId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(messageService.listUnreadMessages(receiverId, page, size));
    }

    @PostMapping("/{id}/read")
    @Operation(summary = "标记消息已读")
    public Result<Void> markAsRead(@PathVariable Long id) {
        messageService.markAsRead(id);
        return Result.success(null);
    }

    @PostMapping("/user/{receiverId}/read-all")
    @Operation(summary = "标记用户所有消息为已读")
    public Result<Void> markAllAsRead(@PathVariable Long receiverId) {
        messageService.markAllAsRead(receiverId);
        return Result.success(null);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除消息")
    public Result<Void> deleteMessage(@PathVariable Long id) {
        messageService.deleteMessage(id);
        return Result.success(null);
    }

    @GetMapping("/user/{receiverId}/unread-count")
    @Operation(summary = "获取用户未读消息数")
    public Result<Long> countUnread(@PathVariable Long receiverId) {
        return Result.success(messageService.countUnread(receiverId));
    }

    @GetMapping("/stats")
    @Operation(summary = "获取消息统计")
    public Result<Map<String, Long>> getMessageStats() {
        return Result.success(messageService.getMessageStats());
    }
}
