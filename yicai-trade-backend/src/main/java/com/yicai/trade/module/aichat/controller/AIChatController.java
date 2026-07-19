package com.yicai.trade.module.aichat.controller;

import com.yicai.trade.module.aichat.dto.ChatRequest;
import com.yicai.trade.module.aichat.dto.ChatResponse;
import com.yicai.trade.module.aichat.service.AIChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "AI Chat", description = "AI智能助手对话接口")
@RestController
@RequestMapping("/api/ai-chat")
@RequiredArgsConstructor
public class AIChatController {

    private final AIChatService chatService;

    @Operation(summary = "Send message to AI assistant")
    @PostMapping("/message")
    public ResponseEntity<ChatResponse> sendMessage(@RequestBody ChatRequest request) {
        ChatResponse response = chatService.chat(request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Health check for AI chat service")
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("AI Chat Service is running");
    }
}
