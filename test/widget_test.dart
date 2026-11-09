import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animation_demo/main.dart';

void main() {
  testWidgets('Thêm công việc mới và đánh dấu hoàn thành', (tester) async {
    await tester.pumpWidget(const AnimationDemoApp());
    expect(find.text('0/3'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Viết báo cáo');
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Viết báo cáo'), findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);

    await tester.tap(find.text('Viết báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('1/4'), findsOneWidget);
  });
}
