import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/services/iap_service.dart';

class MockIapService extends Mock implements IapService {}

void main() {
  group('IapNotifier', () {
    late MockIapService mockIapService;
    late StreamController<bool> purchaseStreamController;

    setUp(() {
      mockIapService = MockIapService();
      purchaseStreamController = StreamController<bool>.broadcast();

      when(() => mockIapService.purchaseStream)
          .thenAnswer((_) => purchaseStreamController.stream);
      when(() => mockIapService.isPurchased).thenReturn(false);
      when(() => mockIapService.isAvailable).thenReturn(true);
      when(() => mockIapService.initialize()).thenAnswer((_) async {});
      when(() => mockIapService.dispose()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await purchaseStreamController.close();
    });

    ProviderContainer buildContainer() {
      final notifier = IapNotifier(iapService: mockIapService);
      final container = ProviderContainer(
        overrides: [
          iapProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);
      // Read the provider to initialize it
      container.read(iapProvider);
      return container;
    }

    test('initial state is IapInitial', () {
      final container = buildContainer();
      expect(container.read(iapProvider), isA<IapInitial>());
    });

    group('initialize', () {
      test(
        'emits [IapLoading, IapNotPurchased] when not purchased',
        () async {
          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).initialize();

          expect(states.length, 2);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapNotPurchased>());
          verify(() => mockIapService.initialize()).called(1);
        },
      );

      test(
        'emits [IapLoading, IapPurchased] when already purchased',
        () async {
          when(() => mockIapService.isPurchased).thenReturn(true);

          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).initialize();

          expect(states.length, 2);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapPurchased>());
        },
      );

      test(
        'emits [IapLoading, IapError] when initialization fails',
        () async {
          when(() => mockIapService.initialize())
              .thenThrow(Exception('init failed'));

          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).initialize();

          expect(states.length, 2);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapError>());
          expect(
            (states[1] as IapError).message,
            contains('init failed'),
          );
        },
      );
    });

    group('purchase', () {
      test('emits [IapLoading] and starts purchase', () async {
        when(() => mockIapService.purchaseAdRemoval())
            .thenAnswer((_) async => true);

        final container = buildContainer();
        final states = <IapState>[];
        container.listen(
          iapProvider,
          (_, next) => states.add(next),
          fireImmediately: false,
        );

        await container.read(iapProvider.notifier).purchase();

        expect(states.length, 1);
        expect(states[0], isA<IapLoading>());
        verify(() => mockIapService.purchaseAdRemoval()).called(1);
      });

      test(
        'emits [IapLoading, IapError] when purchase fails to start',
        () async {
          when(() => mockIapService.purchaseAdRemoval())
              .thenAnswer((_) async => false);

          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).purchase();

          expect(states.length, 2);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapError>());
          expect(
            (states[1] as IapError).message,
            contains('Unable to start purchase'),
          );
        },
      );

      test('emits [IapLoading, IapError] when purchase throws', () async {
        when(() => mockIapService.purchaseAdRemoval())
            .thenThrow(Exception('purchase failed'));

        final container = buildContainer();
        final states = <IapState>[];
        container.listen(
          iapProvider,
          (_, next) => states.add(next),
          fireImmediately: false,
        );

        await container.read(iapProvider.notifier).purchase();

        expect(states.length, 2);
        expect(states[0], isA<IapLoading>());
        expect(states[1], isA<IapError>());
        expect(
          (states[1] as IapError).message,
          contains('purchase failed'),
        );
      });
    });

    group('restore', () {
      test(
        'emits [IapLoading, IapNotPurchased] when nothing to restore',
        () async {
          when(() => mockIapService.restorePurchases())
              .thenAnswer((_) async {});

          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).restore();

          expect(states.length, 2);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapNotPurchased>());
          verify(() => mockIapService.restorePurchases()).called(1);
        },
      );

      test(
        'emits [IapLoading, IapPurchased] when restore finds purchase',
        () async {
          when(() => mockIapService.restorePurchases())
              .thenAnswer((_) async {});
          when(() => mockIapService.isPurchased).thenReturn(true);

          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).restore();

          expect(states.length, 2);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapPurchased>());
        },
      );

      test('emits [IapLoading, IapError] when restore fails', () async {
        when(() => mockIapService.restorePurchases())
            .thenThrow(Exception('restore failed'));

        final container = buildContainer();
        final states = <IapState>[];
        container.listen(
          iapProvider,
          (_, next) => states.add(next),
          fireImmediately: false,
        );

        await container.read(iapProvider.notifier).restore();

        expect(states.length, 2);
        expect(states[0], isA<IapLoading>());
        expect(states[1], isA<IapError>());
        expect(
          (states[1] as IapError).message,
          contains('restore failed'),
        );
      });
    });

    group('purchase stream', () {
      test(
        'emits IapPurchased when stream emits true after init',
        () async {
          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).initialize();
          // states: [IapLoading, IapNotPurchased]

          purchaseStreamController.add(true);
          await Future<void>.delayed(Duration.zero);

          expect(states.length, 3);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapNotPurchased>());
          expect(states[2], isA<IapPurchased>());
        },
      );

      test(
        'emits IapNotPurchased when stream emits false after init',
        () async {
          when(() => mockIapService.isPurchased).thenReturn(true);

          final container = buildContainer();
          final states = <IapState>[];
          container.listen(
            iapProvider,
            (_, next) => states.add(next),
            fireImmediately: false,
          );

          await container.read(iapProvider.notifier).initialize();
          // states: [IapLoading, IapPurchased]

          purchaseStreamController.add(false);
          await Future<void>.delayed(Duration.zero);

          expect(states.length, 3);
          expect(states[0], isA<IapLoading>());
          expect(states[1], isA<IapPurchased>());
          expect(states[2], isA<IapNotPurchased>());
        },
      );
    });
  });

  group('IapState', () {
    test('IapInitial props are empty', () {
      const state = IapInitial();
      expect(state.props, isEmpty);
    });

    test('IapLoading props are empty', () {
      const state = IapLoading();
      expect(state.props, isEmpty);
    });

    test('IapPurchased props are empty', () {
      const state = IapPurchased();
      expect(state.props, isEmpty);
    });

    test('IapNotPurchased props are empty', () {
      const state = IapNotPurchased();
      expect(state.props, isEmpty);
    });

    test('IapError props contain message', () {
      const state = IapError('test error');
      expect(state.props, ['test error']);
    });

    test('IapError supports equality', () {
      const a = IapError('error');
      const b = IapError('error');
      expect(a, equals(b));
    });
  });
}
