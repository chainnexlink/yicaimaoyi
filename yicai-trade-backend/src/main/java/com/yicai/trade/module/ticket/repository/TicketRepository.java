package com.yicai.trade.module.ticket.repository;

import com.yicai.trade.module.ticket.entity.Ticket;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TicketRepository extends JpaRepository<Ticket, Long> {
    Page<Ticket> findByStatus(String status, Pageable pageable);
    Page<Ticket> findByTicketType(String ticketType, Pageable pageable);
    long countByStatus(String status);
}
