package com.yicai.trade.module.message.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.message.dto.BroadcastRequest;
import com.yicai.trade.module.message.dto.MessageRequest;
import com.yicai.trade.module.message.dto.MessageResponse;
import com.yicai.trade.module.message.entity.Message;
import com.yicai.trade.module.message.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MessageServiceImpl implements MessageService {

    private final MessageRepository messageRepository;

    @Override
    @Transactional
    public MessageResponse sendMessage(Long senderId, MessageRequest request) {
        String messageNo = "MSG" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
        Message message = Message.builder()
                .messageNo(messageNo)
                .type(request.getType())
                .title(request.getTitle())
                .content(request.getContent())
                .senderId(senderId)
                .senderName("系统管理员")
                .receiverId(request.getReceiverId())
                .receiverName(request.getReceiverName())
                .relatedId(request.getRelatedId())
                .relatedType(request.getRelatedType())
                .isRead(false)
                .status("ACTIVE")
                .build();
        return toMessageResponse(messageRepository.save(message));
    }

    @Override
    @Transactional
    public MessageResponse sendSystemNotification(Long receiverId, String type, String title, String content, Long relatedId, String relatedType) {
        MessageRequest req = new MessageRequest();
        req.setReceiverId(receiverId);
        req.setType(type != null ? type : "SYSTEM");
        req.setTitle(title);
        req.setContent(content);
        req.setRelatedId(relatedId);
        req.setRelatedType(relatedType);
        return sendMessage(null, req);
    }

    @Override
    @Transactional
    public void sendBroadcast(Long senderId, BroadcastRequest request) {
        // 如果没有指定接收者ID，则发送给所有用户（此处简化处理）
        List<Long> receiverIds = request.getReceiverIds();
        if (receiverIds == null || receiverIds.isEmpty()) {
            // 简化：创建一条广播类型的消息，receiverId为null表示全体
            String messageNo = "BROADCAST" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                    + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
            Message message = Message.builder()
                    .messageNo(messageNo)
                    .type("BROADCAST")
                    .title(request.getTitle())
                    .content(request.getContent())
                    .senderId(senderId)
                    .senderName("系统管理员")
                    .receiverId(null)
                    .receiverName("全体用户")
                    .isRead(false)
                    .status("ACTIVE")
                    .build();
            messageRepository.save(message);
        } else {
            // 为每个接收者创建消息
            for (Long receiverId : receiverIds) {
                String messageNo = "MSG" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                        + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
                Message message = Message.builder()
                        .messageNo(messageNo)
                        .type("BROADCAST")
                        .title(request.getTitle())
                        .content(request.getContent())
                        .senderId(senderId)
                        .senderName("系统管理员")
                        .receiverId(receiverId)
                        .isRead(false)
                        .status("ACTIVE")
                        .build();
                messageRepository.save(message);
            }
        }
    }

    @Override
    public MessageResponse getMessage(Long id) {
        return messageRepository.findById(id)
                .map(this::toMessageResponse)
                .orElseThrow(() -> new RuntimeException("消息不存在: " + id));
    }

    @Override
    public PageResult<MessageResponse> listMessages(Long receiverId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Message> messagePage = messageRepository.findByReceiverIdAndStatus(receiverId, "ACTIVE", pageable);
        List<MessageResponse> content = messagePage.getContent().stream()
                .map(this::toMessageResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, messagePage.getTotalElements(), page, size);
    }

    @Override
    public PageResult<MessageResponse> listMessagesByType(String type, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Message> messagePage = messageRepository.findByType(type, pageable);
        List<MessageResponse> content = messagePage.getContent().stream()
                .map(this::toMessageResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, messagePage.getTotalElements(), page, size);
    }

    @Override
    public PageResult<MessageResponse> listUnreadMessages(Long receiverId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Message> messagePage = messageRepository.findByReceiverIdAndIsRead(receiverId, false, pageable);
        List<MessageResponse> content = messagePage.getContent().stream()
                .map(this::toMessageResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, messagePage.getTotalElements(), page, size);
    }

    @Override
    public PageResult<MessageResponse> listAllMessages(int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Message> messagePage = messageRepository.findAll(pageable);
        List<MessageResponse> content = messagePage.getContent().stream()
                .map(this::toMessageResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, messagePage.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void markAsRead(Long messageId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("消息不存在: " + messageId));
        message.setIsRead(true);
        message.setReadTime(LocalDateTime.now());
        messageRepository.save(message);
    }

    @Override
    @Transactional
    public void markAllAsRead(Long receiverId) {
        List<Message> unreadMessages = messageRepository.findByReceiverIdAndIsReadFalseAndStatus(receiverId, "ACTIVE");
        LocalDateTime now = LocalDateTime.now();
        for (Message message : unreadMessages) {
            message.setIsRead(true);
            message.setReadTime(now);
        }
        messageRepository.saveAll(unreadMessages);
    }

    @Override
    @Transactional
    public void deleteMessage(Long messageId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("消息不存在: " + messageId));
        message.setStatus("DELETED");
        messageRepository.save(message);
    }

    @Override
    public long countUnread(Long receiverId) {
        return messageRepository.countByReceiverIdAndIsRead(receiverId, false);
    }

    @Override
    public Map<String, Long> getMessageStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", messageRepository.count());
        stats.put("system", messageRepository.countByType("SYSTEM"));
        stats.put("order", messageRepository.countByType("ORDER"));
        stats.put("broadcast", messageRepository.countByType("BROADCAST"));
        stats.put("unread", messageRepository.countByIsReadFalse());
        return stats;
    }

    private MessageResponse toMessageResponse(Message message) {
        return MessageResponse.builder()
                .id(message.getId())
                .messageNo(message.getMessageNo())
                .type(message.getType())
                .title(message.getTitle())
                .content(message.getContent())
                .senderId(message.getSenderId())
                .senderName(message.getSenderName())
                .receiverId(message.getReceiverId())
                .receiverName(message.getReceiverName())
                .isRead(message.getIsRead())
                .readTime(message.getReadTime())
                .relatedId(message.getRelatedId())
                .relatedType(message.getRelatedType())
                .status(message.getStatus())
                .createdAt(message.getCreatedAt())
                .build();
    }
}
