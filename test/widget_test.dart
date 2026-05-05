// 过期了么 - 物品保质期管理应用测试
//
// 基础测试验证应用可正常启动

import 'package:flutter_test/flutter_test.dart';
import 'package:guo_qi_le_me/app.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // 构建应用并触发首帧渲染
    await tester.pumpWidget(const GuoQilLeMeApp());

    // 验证应用正常启动（无崩溃）
    expect(find.text('过期了么'), findsWidgets);
  });
}
