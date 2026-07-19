package com.yicai.trade.module.contract.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "ContractChangeRequest", description = "合同变更请求")
public class ContractChangeRequest {

    @NotBlank(message = "变更类型必填")
    @Schema(description = "变更类型: AMENDMENT/TERMINATION/EXTENSION/PRICE_ADJUSTMENT")
    private String changeType;

    @Schema(description = "变更原因")
    private String changeReason;

    @Schema(description = "变更后内容（JSON格式）")
    private String newContent;
}
