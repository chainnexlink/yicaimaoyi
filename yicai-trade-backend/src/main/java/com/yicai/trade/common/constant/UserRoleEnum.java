package com.yicai.trade.common.constant;

public enum UserRoleEnum {
    
    ROLE_ADMIN("ROLE_ADMIN", "管理员"),
    ROLE_BUYER("ROLE_BUYER", "采购商"),
    ROLE_SUPPLIER("ROLE_SUPPLIER", "供应商");
    
    private final String code;
    private final String name;
    
    UserRoleEnum(String code, String name) {
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
