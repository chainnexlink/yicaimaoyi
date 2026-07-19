package com.yicai.trade.common.constant;

public enum UserStatusEnum {
    
    ACTIVE("ACTIVE", "正常"),
    INACTIVE("INACTIVE", "未激活"),
    BANNED("BANNED", "已禁用");
    
    private final String code;
    private final String name;
    
    UserStatusEnum(String code, String name) {
        this.code = code;
        this.name = name;
    }
    
    public String getCode() {
        return code;
    }
    
    public String getName() {
        return name;
    }
}
