package com.yicai.trade.module.buyer.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(name = "BuyerProfileRequest")
public class BuyerProfileRequest {
    private String companyName;
    private String contactPerson;
    private String contactPhone;
    private String address;
    private String industry;
    private String description;
}
