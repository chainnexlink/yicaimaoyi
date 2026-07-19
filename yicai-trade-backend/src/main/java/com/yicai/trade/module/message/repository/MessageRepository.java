package com.yicai.trade.module.message.repository;

import com.yicai.trade.module.message.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    Optional<Message> findByMessageNo(String messageNo);
    Page<Message> findByReceiverId(Long receiverId, Pageable pageable);
    Page<Message> findByReceiverIdAndIsRead(Long receiverId, Boolean isRead, Pageable pageable);
    Page<Message> findByReceiverIdAndStatus(Long receiverId, String status, Pageable pageable);
    Page<Message> findByReceiverIdAndTypeAndStatus(Long receiverId, String type, String status, Pageable pageable);
    Page<Message> findByTypeAndStatus(String type, String status, Pageable pageable);
    Page<Message> findByType(String type, Pageable pageable);
    List<Message> findByReceiverIdAndIsReadFalseAndStatus(Long receiverId, String status);
    long countByReceiverIdAndIsRead(Long receiverId, Boolean isRead);
    long countByReceiverIdAndIsReadFalseAndStatus(Long receiverId, String status);
    long countByType(String type);
    long countByIsReadFalse();
}
