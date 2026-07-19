package com.yicai.trade.common.exception;

import lombok.Getter;

@Getter
public enum ErrorCode {
    
    // 通用错误码 (1000-1099)
    SUCCESS(200, "操作成功"),
    BAD_REQUEST(400, "请求参数错误"),
    UNAUTHORIZED(401, "未认证"),
    FORBIDDEN(403, "无权限访问"),
    NOT_FOUND(404, "资源不存在"),
    INTERNAL_ERROR(500, "服务器内部错误"),
    
    // 通用业务错误码
    SYSTEM_ERROR(1001, "系统错误"),
    RESOURCE_NOT_FOUND(1002, "资源不存在"),
    ACCESS_DENIED(1003, "访问被拒绝"),
    INVALID_OPERATION(1004, "无效操作"),
    INVALID_PARAMETER(1005, "参数无效"),
    
    // 认证错误码 (1100-1199)
    AUTH_INVALID_CREDENTIALS(1101, "用户名或密码错误"),
    AUTH_TOKEN_EXPIRED(1102, "令牌已过期"),
    AUTH_TOKEN_INVALID(1103, "令牌无效"),
    AUTH_USER_DISABLED(1104, "用户已被禁用"),
    AUTH_USER_EXISTS(1105, "用户已存在"),
    AUTH_EMAIL_EXISTS(1106, "邮箱已被注册"),
    AUTH_PHONE_EXISTS(1107, "手机号已被注册"),
    AUTH_VERIFICATION_FAILED(1108, "验证码错误"),
    AUTH_VERIFICATION_EXPIRED(1109, "验证码已过期"),
    AUTH_SMS_SEND_FAILED(1110, "短信发送失败"),
    AUTH_EMAIL_SEND_FAILED(1111, "邮件发送失败"),
    AUTH_EMAIL_NOT_VERIFIED(1112, "邮箱未验证"),
    AUTH_WECHAT_AUTH_FAILED(1113, "微信授权失败"),
    AUTH_ACCOUNT_REQUIRED(1114, "请提供邮箱或手机号"),
    
    // 用户错误码 (1200-1299)
    USER_NOT_FOUND(1201, "用户不存在"),
    USER_PASSWORD_WRONG(1202, "密码错误"),
    
    // 供应商错误码 (2000-2099)
    SUPPLIER_NOT_FOUND(2001, "供应商不存在"),
    SUPPLIER_NOT_APPROVED(2002, "供应商未认证"),
    SUPPLIER_APPLICATION_EXISTS(2003, "已存在入驻申请"),
    
    // 采购商错误码 (2100-2199)
    BUYER_NOT_FOUND(2101, "采购商不存在"),
    
    // 订单错误码 (3000-3099)
    ORDER_NOT_FOUND(3001, "订单不存在"),
    ORDER_STATUS_INVALID(3002, "订单状态不允许当前操作"),
    ORDER_CANNOT_CANCEL(3003, "订单无法取消"),
    
    // 询价错误码 (4000-4099)
    INQUIRY_NOT_FOUND(4001, "询价单不存在"),
    INQUIRY_CLOSED(4002, "询价已关闭"),
    QUOTATION_NOT_FOUND(4003, "报价单不存在"),
    QUOTATION_ALREADY_ACCEPTED(4004, "已有报价被接受"),
    
    // 合同错误码 (5000-5099)
    CONTRACT_NOT_FOUND(5001, "合同不存在"),
    CONTRACT_STATUS_INVALID(5002, "合同状态不允许当前操作"),
    CONTRACT_ALREADY_SIGNED(5003, "合同已签署"),
    CONTRACT_NOT_SIGNED(5004, "合同尚未完成签署"),
    CONTRACT_TEMPLATE_NOT_FOUND(5005, "合同模板不存在"),
    CONTRACT_DUPLICATE(5006, "该报价已生成合同"),
    
    // 监控错误码 (6000-6099)
    MONITOR_NOT_FOUND(6001, "监控记录不存在"),
    MONITOR_SETTING_NOT_FOUND(6002, "监控设置不存在"),
    MONITOR_ALERT_NOT_FOUND(6003, "监控告警不存在"),
    
    // 支付错误码 (7000-7099)
    PAYMENT_NOT_FOUND(7001, "支付记录不存在"),
    PAYMENT_ALREADY_PAID(7002, "订单已支付"),
    PAYMENT_EXPIRED(7003, "支付已过期"),
    PAYMENT_AMOUNT_MISMATCH(7004, "支付金额不匹配"),
    PAYMENT_STATUS_INVALID(7005, "支付状态不允许当前操作"),
    REFUND_NOT_FOUND(7006, "退款记录不存在"),
    REFUND_AMOUNT_EXCEED(7007, "退款金额超过支付金额"),
    REFUND_ALREADY_PROCESSED(7008, "退款已处理"),
    REFUND_STATUS_INVALID(7009, "退款状态不允许当前操作"),
    PAYMENT_GATEWAY_ERROR(7010, "支付网关异常"),
    PAYMENT_CALLBACK_INVALID(7011, "支付回调验证失败"),
    REFUND_ALREADY_EXISTS(7013, "该订单已存在退款申请"),
    REFUND_NOT_ALLOWED(7014, "当前订单状态不允许退款"),
    PAYMENT_METHOD_NOT_SUPPORTED(7017, "不支持的支付方式"),
    PAYMENT_DUPLICATE(7018, "重复支付请求"),

    // 托管错误码 (8000-8099)
    ESCROW_NOT_FOUND(8001, "托管记录不存在"),
    ESCROW_STATUS_INVALID(8002, "托管状态不允许当前操作"),
    ESCROW_ALREADY_EXISTS(8003, "该订单已存在托管记录");
    
    private final int code;
    private final String message;
    
    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
}
