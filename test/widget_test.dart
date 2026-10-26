import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:productivity_app/app.dart';

void main() {
  testWidgets('App boots to the Today screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ProductivityApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
  });
}
