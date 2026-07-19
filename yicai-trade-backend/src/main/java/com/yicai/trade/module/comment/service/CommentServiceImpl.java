package com.yicai.trade.module.comment.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.comment.dto.CommentResponse;
import com.yicai.trade.module.comment.entity.Comment;
import com.yicai.trade.module.comment.repository.CommentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommentServiceImpl implements CommentService {

    private final CommentRepository commentRepository;

    @Override
    public PageResult<CommentResponse> list(String status, String sourceType, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Comment> p;
        if (status != null && !status.isEmpty() && sourceType != null && !sourceType.isEmpty()) {
            p = commentRepository.findByStatusAndSourceType(status, sourceType, pageable);
        } else if (status != null && !status.isEmpty()) {
            p = commentRepository.findByStatus(status, pageable);
        } else if (sourceType != null && !sourceType.isEmpty()) {
            p = commentRepository.findBySourceType(sourceType, pageable);
        } else {
            p = commentRepository.findAll(pageable);
        }
        List<CommentResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void approve(Long id) {
        Comment c = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Comment not found: " + id));
        c.setStatus("APPROVED");
        commentRepository.save(c);
    }

    @Override
    @Transactional
    public void hide(Long id) {
        Comment c = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Comment not found: " + id));
        c.setStatus("HIDDEN");
        commentRepository.save(c);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        commentRepository.deleteById(id);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", commentRepository.count());
        stats.put("pending", commentRepository.countByStatus("PENDING"));
        stats.put("approved", commentRepository.countByStatus("APPROVED"));
        stats.put("hidden", commentRepository.countByStatus("HIDDEN"));
        return stats;
    }

    private CommentResponse toResponse(Comment c) {
        CommentResponse r = new CommentResponse();
        r.setId(c.getId());
        r.setUserId(c.getUserId());
        r.setUserName(c.getUserName());
        r.setSourceType(c.getSourceType());
        r.setSourceId(c.getSourceId());
        r.setContent(c.getContent());
        r.setRating(c.getRating());
        r.setStatus(c.getStatus());
        r.setCreatedAt(c.getCreatedAt());
        return r;
    }
}
