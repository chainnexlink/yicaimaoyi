package com.yicai.trade.module.logistics.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.logistics.dto.*;
import com.yicai.trade.module.logistics.entity.Logistics;
import com.yicai.trade.module.logistics.entity.LogisticsTrack;
import com.yicai.trade.module.logistics.gateway.LogisticsTrackingGateway;
import com.yicai.trade.module.logistics.repository.LogisticsRepository;
import com.yicai.trade.module.logistics.repository.LogisticsTrackRepository;
import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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

@Slf4j
@Service
@RequiredArgsConstructor
public class LogisticsServiceImpl implements LogisticsService {

    private final LogisticsRepository logisticsRepository;
    private final LogisticsTrackRepository logisticsTrackRepository;
    private final OrderRepository orderRepository;
    private final MessageService messageService;
    private final LogisticsTrackingGateway logisticsTrackingGateway;

    @Override
    @Transactional
    public LogisticsResponse create(LogisticsRequest request) {
        Logistics logistics = Logistics.builder()
                .trackingNo("LG" + System.currentTimeMillis())
                .orderId(request.getOrderId())
                .orderNo(request.getOrderNo())
                .senderName(request.getSenderName())
                .senderAddress(request.getSenderAddress())
                .receiverName(request.getReceiverName())
                .receiverAddress(request.getReceiverAddress())
                .carrier(request.getCarrier())
                .status("SHIPPING")
                .shippedAt(LocalDateTime.now())
                .remark(request.getRemark())
                .build();
        return toResponse(logisticsRepository.save(logistics));
    }

    @Override
    public LogisticsResponse getById(Long id) {
        return logisticsRepository.findById(id).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("Logistics not found: " + id));
    }

    @Override
    public LogisticsResponse getByTrackingNo(String trackingNo) {
        return logisticsRepository.findByTrackingNo(trackingNo).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("Logistics not found: " + trackingNo));
    }

    @Override
    public PageResult<LogisticsResponse> list(String status, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Logistics> p = (status != null && !status.isEmpty())
                ? logisticsRepository.findByStatus(status, pageable)
                : logisticsRepository.findAll(pageable);
        List<LogisticsResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void updateStatus(Long id, String status) {
        Logistics logistics = logisticsRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Logistics not found: " + id));
        logistics.setStatus(status);
        if ("DELIVERED".equals(status)) {
            logistics.setDeliveredAt(LocalDateTime.now());
            // 通知买家确认收货
            if (logistics.getOrderId() != null) {
                try {
                    Order order = orderRepository.findById(logistics.getOrderId()).orElse(null);
                    if (order != null && "SHIPPED".equals(order.getStatus())) {
                        messageService.sendSystemNotification(order.getBuyerId(),
                                "LOGISTICS", "物流已送达，请确认收货",
                                "订单 " + order.getOrderNo() + " 的物流（" + logistics.getCarrier()
                                        + " " + logistics.getTrackingNo() + "）已送达，请及时确认收货。",
                                order.getId(), null);
                    }
                } catch (Exception e) {
                    log.warn("物流送达通知失败: logisticsId={}, error={}", id, e.getMessage());
                }
            }
        }
        logisticsRepository.save(logistics);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", logisticsRepository.count());
        stats.put("shipping", logisticsRepository.countByStatus("SHIPPING"));
        stats.put("delivered", logisticsRepository.countByStatus("DELIVERED"));
        stats.put("exception", logisticsRepository.countByStatus("EXCEPTION"));
        return stats;
    }

    private LogisticsResponse toResponse(Logistics l) {
        LogisticsResponse r = new LogisticsResponse();
        r.setId(l.getId());
        r.setTrackingNo(l.getTrackingNo());
        r.setOrderId(l.getOrderId());
        r.setOrderNo(l.getOrderNo());
        r.setSenderName(l.getSenderName());
        r.setSenderAddress(l.getSenderAddress());
        r.setReceiverName(l.getReceiverName());
        r.setReceiverAddress(l.getReceiverAddress());
        r.setCarrier(l.getCarrier());
        r.setStatus(l.getStatus());
        r.setShippedAt(l.getShippedAt());
        r.setDeliveredAt(l.getDeliveredAt());
        r.setRemark(l.getRemark());
        r.setCreatedAt(l.getCreatedAt());
        return r;
    }

    @Override
    public TrackingQueryResponse queryTracking(String trackingNo, String carrierCode) {
        TrackingQueryResponse response = logisticsTrackingGateway.queryTracking(trackingNo, carrierCode);

        // 查询成功时，将轨迹数据持久化到 t_logistics_track 表
        if (response.isSuccess() && response.getTracks() != null && !response.getTracks().isEmpty()) {
            try {
                persistTrackingData(trackingNo, response);
            } catch (Exception e) {
                log.warn("持久化物流轨迹数据失败: trackingNo={}, error={}", trackingNo, e.getMessage());
            }
        }

        return response;
    }

    /**
     * 将第三方API返回的轨迹数据保存到数据库
     */
    @Transactional
    protected void persistTrackingData(String trackingNo, TrackingQueryResponse response) {
        Logistics logistics = logisticsRepository.findByTrackingNo(trackingNo).orElse(null);
        if (logistics == null) {
            log.debug("未找到本地物流记录，跳过持久化: trackingNo={}", trackingNo);
            return;
        }

        // 清除旧轨迹，写入最新数据
        logisticsTrackRepository.deleteByLogisticsId(logistics.getId());

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        List<LogisticsTrack> tracks = response.getTracks().stream().map(node -> {
            LocalDateTime nodeTime;
            try {
                nodeTime = LocalDateTime.parse(node.getTime(), formatter);
            } catch (Exception e) {
                nodeTime = LocalDateTime.now();
            }
            return LogisticsTrack.builder()
                    .logisticsId(logistics.getId())
                    .trackingNo(trackingNo)
                    .nodeTime(nodeTime)
                    .description(node.getStatus())
                    .status(response.getDeliveryStatus())
                    .build();
        }).collect(Collectors.toList());

        logisticsTrackRepository.saveAll(tracks);

        // 根据API返回的投递状态更新物流主记录
        if ("3".equals(response.getDeliveryStatus()) && !"DELIVERED".equals(logistics.getStatus())) {
            updateStatus(logistics.getId(), "DELIVERED");
        } else if ("4".equals(response.getDeliveryStatus()) && !"EXCEPTION".equals(logistics.getStatus())) {
            updateStatus(logistics.getId(), "EXCEPTION");
        }

        // 更新承运商名称
        if (response.getCarrierName() != null && !response.getCarrierName().isEmpty()
                && (logistics.getCarrier() == null || logistics.getCarrier().isEmpty())) {
            logistics.setCarrier(response.getCarrierName());
            logisticsRepository.save(logistics);
        }

        log.info("物流轨迹已持久化: trackingNo={}, nodes={}", trackingNo, tracks.size());
    }
}
