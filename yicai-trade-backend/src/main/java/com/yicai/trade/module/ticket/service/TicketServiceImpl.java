package com.yicai.trade.module.ticket.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.ticket.dto.*;
import com.yicai.trade.module.ticket.entity.Ticket;
import com.yicai.trade.module.ticket.repository.TicketRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TicketServiceImpl implements TicketService {

    private final TicketRepository ticketRepository;

    @Override
    @Transactional
    public TicketResponse create(TicketRequest request) {
        Ticket ticket = Ticket.builder()
                .ticketNo("TK" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")))
                .userId(request.getUserId())
                .userName(request.getUserName())
                .ticketType(request.getTicketType())
                .title(request.getTitle())
                .content(request.getContent())
                .priority(request.getPriority() != null ? request.getPriority() : "NORMAL")
                .status("OPEN")
                .build();
        return toResponse(ticketRepository.save(ticket));
    }

    @Override
    public TicketResponse getById(Long id) {
        return ticketRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
    }

    @Override
    public PageResult<TicketResponse> list(String status, String ticketType, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Ticket> p;
        if (status != null && !status.isEmpty()) {
            p = ticketRepository.findByStatus(status, pageable);
        } else if (ticketType != null && !ticketType.isEmpty()) {
            p = ticketRepository.findByTicketType(ticketType, pageable);
        } else {
            p = ticketRepository.findAll(pageable);
        }
        List<TicketResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void reply(Long id, String replyContent) {
        Ticket ticket = ticketRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
        ticket.setReplyContent(replyContent);
        ticket.setRepliedAt(LocalDateTime.now());
        ticket.setStatus("PROCESSING");
        ticketRepository.save(ticket);
    }

    @Override
    @Transactional
    public void close(Long id) {
        Ticket ticket = ticketRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
        ticket.setStatus("CLOSED");
        ticketRepository.save(ticket);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", ticketRepository.count());
        stats.put("open", ticketRepository.countByStatus("OPEN"));
        stats.put("processing", ticketRepository.countByStatus("PROCESSING"));
        stats.put("closed", ticketRepository.countByStatus("CLOSED"));
        return stats;
    }

    private TicketResponse toResponse(Ticket t) {
        TicketResponse r = new TicketResponse();
        r.setId(t.getId());
        r.setTicketNo(t.getTicketNo());
        r.setUserId(t.getUserId());
        r.setUserName(t.getUserName());
        r.setTicketType(t.getTicketType());
        r.setTitle(t.getTitle());
        r.setContent(t.getContent());
        r.setPriority(t.getPriority());
        r.setStatus(t.getStatus());
        r.setReplyContent(t.getReplyContent());
        r.setRepliedAt(t.getRepliedAt());
        r.setCreatedAt(t.getCreatedAt());
        return r;
    }
}
