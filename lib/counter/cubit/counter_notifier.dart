import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for the counter.
final counterProvider =
    NotifierProvider<CounterNotifier, int>(CounterNotifier.new);

/// Notifier for managing a simple counter.
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
}
