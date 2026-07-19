/// 登录请求模型
class LoginRequest {
  final String account;
  final String password;
  final String? userType;

  const LoginRequest({
    required this.account,
    required this.password,
    this.userType,
  });

  Map<String, dynamic> toJson() => {
    'username': account,
    'password': password,
    if (userType != null) 'userType': userType,
  };
}
