package com.yicai.trade.module.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NonNull;

@Data
@Schema(name = "SupplierApplicationRequest")
public class SupplierApplicationRequest {
    @NonNull
    @NotBlank(message = "companyName required")
    @Schema(description = "companyName")
    private String companyName;
    @Schema(description = "contactPerson")
    private String contactPerson;
    @Schema(description = "contactPhone")
    private String contactPhone;
    @Schema(description = "businessLicense")
    private String businessLicense;
    @Schema(description = "address")
    private String address;
    @Schema(description = "description")
    private String description;
}
