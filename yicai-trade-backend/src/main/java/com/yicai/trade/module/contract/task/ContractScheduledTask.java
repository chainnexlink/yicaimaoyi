package com.yicai.trade.module.contract.task;

import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.message.service.MessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * 合同定时任务：自动过期已超期的合同
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ContractScheduledTask {

    private final ContractRepository contractRepository;
    private final MessageService messageService;

    /**
     * 每天凌晨1点扫描，将 endDate < 今天 且仍在EXECUTING的合同标记为EXPIRED
     */
    @Scheduled(cron = "0 0 1 * * ?")
    @Transactional
    public void autoExpireContracts() {
        List<Contract> expiredList = contractRepository.findExpiredExecutingContracts(LocalDate.now());

        if (expiredList.isEmpty()) {
            return;
        }

        log.info("定时任务：发现 {} 份已过期合同，开始自动过期处理", expiredList.size());

        for (Contract contract : expiredList) {
            try {
                contract.setStatus("EXPIRED");
                contractRepository.save(contract);

                String msg = "合同 " + contract.getContractNo() + " 已超过到期日（"
                        + contract.getEndDate() + "），系统已自动标记为过期。如需继续执行，请联系平台续签。";
                messageService.sendSystemNotification(contract.getBuyerId(),
                        "CONTRACT", "合同已过期", msg, contract.getId(), null);
                messageService.sendSystemNotification(contract.getSupplierId(),
                        "CONTRACT", "合同已过期", msg, contract.getId(), null);

                log.info("合同已自动过期: contractNo={}, endDate={}", contract.getContractNo(), contract.getEndDate());
            } catch (Exception e) {
                log.error("合同自动过期处理失败: contractId={}, error={}", contract.getId(), e.getMessage());
            }
        }
    }
}
