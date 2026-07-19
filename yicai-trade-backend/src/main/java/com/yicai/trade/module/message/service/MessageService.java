package com.yicai.trade.module.message.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.message.dto.BroadcastRequest;
import com.yicai.trade.module.message.dto.MessageRequest;
import com.yicai.trade.module.message.dto.MessageResponse;

import java.util.Map;

public interface MessageService {
    // 发送消息
    MessageResponse sendMessage(Long senderId, MessageRequest request);
    void sendBroadcast(Long senderId, BroadcastRequest request);
    
    /** 便捷方法：发送系统通知（不需要构造 MessageRequest） */
    MessageResponse sendSystemNotification(Long receiverId, String type, String title, String content, Long relatedId, String relatedType);
    
    // 消息查询
    MessageResponse getMessage(Long id);
    PageResult<MessageResponse> listMessages(Long receiverId, int page, int size);
    PageResult<MessageResponse> listMessagesByType(String type, int page, int size);
    PageResult<MessageResponse> listUnreadMessages(Long receiverId, int page, int size);
    PageResult<MessageResponse> listAllMessages(int page, int size);
    
    // 消息操作
    void markAsRead(Long messageId);
    void markAllAsRead(Long receiverId);
    void deleteMessage(Long messageId);
    
    // 统计
    long countUnread(Long receiverId);
    Map<String, Long> getMessageStats();
}
