// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/app/app.dart';
import 'package:randoeats/screens/screens.dart';

void main() {
  group('App', () {
    testWidgets('renders HomeScreen', (tester) async {
      await tester.pumpWidget(App());
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
