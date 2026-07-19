package com.yicai.trade.module.comment.repository;

import com.yicai.trade.module.comment.entity.Comment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommentRepository extends JpaRepository<Comment, Long> {
    Page<Comment> findByStatus(String status, Pageable pageable);
    Page<Comment> findBySourceType(String sourceType, Pageable pageable);
    Page<Comment> findByStatusAndSourceType(String status, String sourceType, Pageable pageable);
    long countByStatus(String status);
}
