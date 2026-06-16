// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/screens/screens.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

const _testRestaurants = [
  Restaurant(
    placeId: 'place_1',
    name: 'Restaurant One',
    address: '123 Main St',
    latitude: 34,
    longitude: -118,
    rating: 4.5,
    isOpen: true,
  ),
  Restaurant(
    placeId: 'place_2',
    name: 'Restaurant Two',
    address: '456 Oak Ave',
    latitude: 34,
    longitude: -118,
    rating: 4,
    isOpen: true,
  ),
];

class _FixedDiscoveryNotifier extends DiscoveryNotifier {
  _FixedDiscoveryNotifier(this._initialState);

  final DiscoveryState _initialState;

  @override
  DiscoveryState build() => _initialState;
}

void main() {
  group('ResultsScreen', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(status: DiscoveryStatus.loading),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Scanning nearby quadrants...'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(
                  status: DiscoveryStatus.failure,
                  errorMessage: 'Test error message',
                ),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.text('Houston, we have a problem'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders success state with restaurants', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(
                  status: DiscoveryStatus.success,
                  restaurants: _testRestaurants,
                ),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.byType(MultiReelSlotMachine), findsOneWidget);
      expect(find.byType(RandoEatsButton), findsOneWidget);
    });

    testWidgets('renders settings icon', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(
                  status: DiscoveryStatus.success,
                  restaurants: _testRestaurants,
                ),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders refresh button in success state', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(
                  status: DiscoveryStatus.success,
                  restaurants: _testRestaurants,
                ),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders initial state as loading', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders warning icon in error state', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => _FixedDiscoveryNotifier(
                const DiscoveryState(
                  status: DiscoveryStatus.failure,
                  errorMessage: 'Error',
                ),
              ),
            ),
          ],
          child: ResultsScreen(),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
