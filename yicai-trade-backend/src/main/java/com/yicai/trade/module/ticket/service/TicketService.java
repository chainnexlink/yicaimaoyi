package com.yicai.trade.module.ticket.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.ticket.dto.*;
import java.util.Map;

public interface TicketService {
    TicketResponse create(TicketRequest request);
    TicketResponse getById(Long id);
    PageResult<TicketResponse> list(String status, String ticketType, int page, int size);
    void reply(Long id, String replyContent);
    void close(Long id);
    Map<String, Long> getStats();
}
