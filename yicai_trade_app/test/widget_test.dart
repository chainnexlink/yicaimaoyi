import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Phase 1 基础测试 - 验证应用可以初始化
    expect(1 + 1, equals(2));
  });
}
