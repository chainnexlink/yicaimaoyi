package com.yicai.trade.module.certification.dto;

import lombok.Data;

@Data
public class CertificationRequest {
    // 企业基本信息
    private Long companyId;
    private String companyName;
    private String creditCode;
    private String companyType;
    private String registeredCapital;
    private String foundDate;
    private String companyAddress;

    // 法人信息
    private String legalName;
    private String legalIdNumber;
    private String legalPhone;
    private String legalIdFront;
    private String legalIdBack;

    // 资质证书
    private String businessLicense;
    private String certType;
    private String otherCerts;

    // 联系人信息
    private String contactName;
    private String contactTitle;
    private String contactPhone;
    private String contactEmail;
}
