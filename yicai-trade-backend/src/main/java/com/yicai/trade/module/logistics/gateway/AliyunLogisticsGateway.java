package com.yicai.trade.module.logistics.gateway;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.logistics.dto.TrackingQueryResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.ArrayList;
import java.util.List;

/**
 * 阿里云API市场 - 全球快递物流查询网关实现
 * API文档: https://market.aliyun.com 全球快递物流查询
 */
@Slf4j
@Component
public class AliyunLogisticsGateway implements LogisticsTrackingGateway {

    private static final String DEFAULT_API_URL = "https://wuliu.market.alicloudapi.com/kdi";

    @Value("${logistics.tracking.api-url:" + DEFAULT_API_URL + "}")
    private String apiUrl;

    @Value("${logistics.tracking.app-code:}")
    private String appCode;

    @Value("${logistics.tracking.enabled:true}")
    private boolean enabled;

    @Value("${logistics.tracking.timeout:10000}")
    private int timeout;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public AliyunLogisticsGateway(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        // 独立的RestTemplate，避免影响其他模块的超时配置
        this.restTemplate = new RestTemplate();
    }

    @Override
    public TrackingQueryResponse queryTracking(String trackingNo, String carrierCode) {
        TrackingQueryResponse response = new TrackingQueryResponse();
        response.setTrackingNo(trackingNo);

        if (!enabled || appCode == null || appCode.isEmpty()) {
            response.setSuccess(false);
            response.setErrorMsg("物流查询服务未配置或未启用");
            log.warn("物流查询服务未启用: enabled={}, appCode配置={}", enabled, appCode != null && !appCode.isEmpty());
            return response;
        }

        try {
            // 构建请求URL
            UriComponentsBuilder uriBuilder = UriComponentsBuilder.fromHttpUrl(apiUrl)
                    .queryParam("no", trackingNo);
            if (carrierCode != null && !carrierCode.isEmpty()) {
                uriBuilder.queryParam("type", carrierCode);
            }
            String requestUrl = uriBuilder.toUriString();

            // 设置请求头
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "APPCODE " + appCode);
            headers.setAccept(List.of(MediaType.APPLICATION_JSON));

            HttpEntity<Void> entity = new HttpEntity<>(headers);

            log.info("物流查询请求: trackingNo={}, carrierCode={}", trackingNo, carrierCode);

            // 发送请求
            ResponseEntity<String> httpResponse = restTemplate.exchange(
                    requestUrl, HttpMethod.GET, entity, String.class);

            if (httpResponse.getStatusCode() == HttpStatus.OK && httpResponse.getBody() != null) {
                return parseResponse(httpResponse.getBody(), trackingNo);
            } else {
                response.setSuccess(false);
                response.setErrorMsg("物流查询接口返回异常: HTTP " + httpResponse.getStatusCode());
            }
        } catch (Exception e) {
            log.error("物流查询失败: trackingNo={}, error={}", trackingNo, e.getMessage(), e);
            response.setSuccess(false);
            response.setErrorMsg("物流查询请求失败: " + e.getMessage());
        }

        return response;
    }

    /**
     * 解析阿里云API市场返回的JSON
     * 格式: {"status":"0","msg":"ok","result":{"number":"xxx","type":"zto","typename":"中通快递",
     *        "list":[{"time":"2026-03-20 12:00:00","status":"已签收"}],
     *        "deliverystatus":"3","issign":"1"}}
     */
    private TrackingQueryResponse parseResponse(String body, String trackingNo) {
        TrackingQueryResponse response = new TrackingQueryResponse();
        response.setTrackingNo(trackingNo);

        try {
            JsonNode root = objectMapper.readTree(body);
            String status = root.path("status").asText("");

            if (!"0".equals(status)) {
                response.setSuccess(false);
                response.setErrorMsg(root.path("msg").asText("查询失败"));
                log.warn("物流查询返回错误: trackingNo={}, status={}, msg={}", trackingNo, status, root.path("msg").asText());
                return response;
            }

            JsonNode result = root.path("result");
            response.setSuccess(true);
            response.setCarrierCode(result.path("type").asText(""));
            response.setCarrierName(result.path("typename").asText(""));
            response.setDeliveryStatus(result.path("deliverystatus").asText(""));
            response.setSigned(result.path("issign").asText("0"));

            // 解析轨迹列表
            List<TrackingQueryResponse.TrackNode> tracks = new ArrayList<>();
            JsonNode listNode = result.path("list");
            if (listNode.isArray()) {
                for (JsonNode item : listNode) {
                    TrackingQueryResponse.TrackNode node = new TrackingQueryResponse.TrackNode();
                    node.setTime(item.path("time").asText(""));
                    node.setStatus(item.path("status").asText(""));
                    tracks.add(node);
                }
            }
            response.setTracks(tracks);

            log.info("物流查询成功: trackingNo={}, carrier={}, nodes={}, deliveryStatus={}",
                    trackingNo, response.getCarrierName(), tracks.size(), response.getDeliveryStatus());

        } catch (Exception e) {
            log.error("解析物流查询响应失败: trackingNo={}, body={}", trackingNo, body, e);
            response.setSuccess(false);
            response.setErrorMsg("解析响应数据失败");
        }

        return response;
    }
}
