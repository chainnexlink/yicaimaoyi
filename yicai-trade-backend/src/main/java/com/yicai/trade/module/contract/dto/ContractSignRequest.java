package com.yicai.trade.module.contract.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(name = "ContractSignRequest", description = "合同签署请求（简化版一键签署）")
public class ContractSignRequest {

    @Schema(description = "签署人名称（自动填充，可选）")
    private String signature;

    @Schema(description = "签署备注（可选）")
    private String remark;
}
