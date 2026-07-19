package com.yicai.trade.module.inquiry.task;

import com.yicai.trade.module.inquiry.entity.Inquiry;
import com.yicai.trade.module.inquiry.repository.InquiryRepository;
import com.yicai.trade.module.message.service.MessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 询价定时任务：自动关闭已过期的询价单
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class InquiryScheduledTask {

    private final InquiryRepository inquiryRepository;
    private final MessageService messageService;

    /**
     * 每10分钟扫描一次，将超过 deadline 的 OPEN 询价自动关闭
     */
    @Scheduled(fixedDelay = 10 * 60 * 1000, initialDelay = 2 * 60 * 1000)
    @Transactional
    public void autoCloseExpiredInquiries() {
        List<Inquiry> expiredList = inquiryRepository
                .findByStatusAndDeadlineBefore("OPEN", LocalDateTime.now());

        if (expiredList.isEmpty()) {
            return;
        }

        log.info("定时任务：发现 {} 条已过期询价，开始自动关闭", expiredList.size());

        for (Inquiry inquiry : expiredList) {
            try {
                inquiry.setStatus("CLOSED");
                inquiryRepository.save(inquiry);

                messageService.sendSystemNotification(inquiry.getBuyerId(),
                        "INQUIRY", "询价已自动关闭",
                        "您的询价「" + inquiry.getTitle() + "」已超过截止日期，系统已自动关闭。",
                        inquiry.getId(), null);

                log.info("询价已自动关闭: id={}, title={}, deadline={}",
                        inquiry.getId(), inquiry.getTitle(), inquiry.getDeadline());
            } catch (Exception e) {
                log.error("询价自动关闭失败: inquiryId={}, error={}", inquiry.getId(), e.getMessage());
            }
        }

        log.info("定时任务：询价自动关闭完成，共 {} 条", expiredList.size());
    }
}
