// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:randoeats/counter/counter.dart';

import '../../helpers/helpers.dart';

void main() {
  group('CounterPage', () {
    testWidgets('renders CounterView', (tester) async {
      await tester.pumpApp(
        ProviderScope(child: CounterPage()),
      );
      expect(find.byType(CounterView), findsOneWidget);
    });
  });

  group('CounterView', () {
    testWidgets('renders current count', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            counterProvider.overrideWith(() => _FixedCounterNotifier(42)),
          ],
          child: const CounterView(),
        ),
      );
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('calls increment when increment button is tapped', (
      tester,
    ) async {
      await tester.pumpApp(
        ProviderScope(child: const CounterView()),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('calls decrement when decrement button is tapped', (
      tester,
    ) async {
      await tester.pumpApp(
        ProviderScope(child: const CounterView()),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('-1'), findsOneWidget);
    });
  });
}

class _FixedCounterNotifier extends CounterNotifier {
  _FixedCounterNotifier(this._initialValue);

  final int _initialValue;

  @override
  int build() => _initialValue;
}
