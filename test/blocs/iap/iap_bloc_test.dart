import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/services/iap_service.dart';

class MockIapService extends Mock implements IapService {}

void main() {
  group('IapBloc', () {
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

    IapBloc buildBloc() => IapBloc(iapService: mockIapService);

    test('initial state is IapInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<IapInitial>());
      addTearDown(bloc.close);
    });

    group('IapInitialized', () {
      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapNotPurchased] when not purchased',
        build: buildBloc,
        act: (bloc) => bloc.add(const IapInitialized()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapNotPurchased>(),
        ],
        verify: (_) {
          verify(() => mockIapService.initialize()).called(1);
        },
      );

      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapPurchased] when already purchased',
        setUp: () {
          when(() => mockIapService.isPurchased).thenReturn(true);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapInitialized()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapPurchased>(),
        ],
      );

      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapError] when initialization fails',
        setUp: () {
          when(() => mockIapService.initialize())
              .thenThrow(Exception('init failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapInitialized()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapError>().having(
            (s) => s.message,
            'message',
            contains('init failed'),
          ),
        ],
      );
    });

    group('IapPurchaseRequested', () {
      blocTest<IapBloc, IapState>(
        'emits [IapLoading] and starts purchase',
        setUp: () {
          when(() => mockIapService.purchaseAdRemoval())
              .thenAnswer((_) async => true);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapPurchaseRequested()),
        expect: () => [
          isA<IapLoading>(),
        ],
        verify: (_) {
          verify(() => mockIapService.purchaseAdRemoval()).called(1);
        },
      );

      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapError] when purchase fails to start',
        setUp: () {
          when(() => mockIapService.purchaseAdRemoval())
              .thenAnswer((_) async => false);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapPurchaseRequested()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapError>().having(
            (s) => s.message,
            'message',
            contains('Unable to start purchase'),
          ),
        ],
      );

      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapError] when purchase throws',
        setUp: () {
          when(() => mockIapService.purchaseAdRemoval())
              .thenThrow(Exception('purchase failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapPurchaseRequested()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapError>().having(
            (s) => s.message,
            'message',
            contains('purchase failed'),
          ),
        ],
      );
    });

    group('IapRestoreRequested', () {
      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapNotPurchased] when nothing to restore',
        setUp: () {
          when(() => mockIapService.restorePurchases())
              .thenAnswer((_) async {});
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapRestoreRequested()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapNotPurchased>(),
        ],
        verify: (_) {
          verify(() => mockIapService.restorePurchases()).called(1);
        },
      );

      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapPurchased] when restore finds purchase',
        setUp: () {
          when(() => mockIapService.restorePurchases())
              .thenAnswer((_) async {});
          when(() => mockIapService.isPurchased).thenReturn(true);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapRestoreRequested()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapPurchased>(),
        ],
      );

      blocTest<IapBloc, IapState>(
        'emits [IapLoading, IapError] when restore fails',
        setUp: () {
          when(() => mockIapService.restorePurchases())
              .thenThrow(Exception('restore failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const IapRestoreRequested()),
        expect: () => [
          isA<IapLoading>(),
          isA<IapError>().having(
            (s) => s.message,
            'message',
            contains('restore failed'),
          ),
        ],
      );
    });

    group('purchase stream', () {
      blocTest<IapBloc, IapState>(
        'emits IapPurchased when stream emits true after init',
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const IapInitialized());
          await Future<void>.delayed(Duration.zero);
          purchaseStreamController.add(true);
        },
        expect: () => [
          isA<IapLoading>(),
          isA<IapNotPurchased>(),
          isA<IapPurchased>(),
        ],
      );

      blocTest<IapBloc, IapState>(
        'emits IapNotPurchased when stream emits false after init',
        setUp: () {
          when(() => mockIapService.isPurchased).thenReturn(true);
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const IapInitialized());
          await Future<void>.delayed(Duration.zero);
          purchaseStreamController.add(false);
        },
        expect: () => [
          isA<IapLoading>(),
          isA<IapPurchased>(),
          isA<IapNotPurchased>(),
        ],
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

  group('IapEvent', () {
    test('IapInitialized props are empty', () {
      const event = IapInitialized();
      expect(event.props, isEmpty);
    });

    test('IapPurchaseRequested props are empty', () {
      const event = IapPurchaseRequested();
      expect(event.props, isEmpty);
    });

    test('IapRestoreRequested props are empty', () {
      const event = IapRestoreRequested();
      expect(event.props, isEmpty);
    });
  });
}
