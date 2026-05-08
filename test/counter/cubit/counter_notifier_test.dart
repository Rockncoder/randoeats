import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:randoeats/counter/counter.dart';

void main() {
  group('CounterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state is 0', () {
      expect(container.read(counterProvider), equals(0));
    });

    test('emits [1] when increment is called', () {
      container.read(counterProvider.notifier).increment();
      expect(container.read(counterProvider), equals(1));
    });

    test('emits [-1] when decrement is called', () {
      container.read(counterProvider.notifier).decrement();
      expect(container.read(counterProvider), equals(-1));
    });
  });
}
