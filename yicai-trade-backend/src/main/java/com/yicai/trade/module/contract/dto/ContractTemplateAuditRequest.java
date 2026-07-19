package com.yicai.trade.module.contract.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContractTemplateAuditRequest {

    private boolean approved;

    private String auditNote;
}
