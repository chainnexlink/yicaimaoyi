/// 注册请求模型
class RegisterRequest {
  final String username;
  final String password;
  final String? email;
  final String? phone;
  final String userType;
  final String? verificationCode;

  const RegisterRequest({
    required this.username,
    required this.password,
    this.email,
    this.phone,
    this.userType = 'BUYER',
    this.verificationCode,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    'userType': userType,
    if (verificationCode != null) 'verificationCode': verificationCode,
  };
}
