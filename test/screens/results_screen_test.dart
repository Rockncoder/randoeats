// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/screens/screens.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

class MockDiscoveryBloc extends MockBloc<DiscoveryEvent, DiscoveryState>
    implements DiscoveryBloc {}

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

void main() {
  group('ResultsScreen', () {
    late MockDiscoveryBloc mockBloc;

    setUp(() {
      mockBloc = MockDiscoveryBloc();
    });

    testWidgets('renders loading state', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(status: DiscoveryStatus.loading),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Scanning nearby quadrants...'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(
          status: DiscoveryStatus.failure,
          errorMessage: 'Test error message',
        ),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.text('Houston, we have a problem'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders success state with restaurants', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(
          status: DiscoveryStatus.success,
          restaurants: _testRestaurants,
        ),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.byType(SlotMachineList), findsOneWidget);
      expect(find.byType(RandoEatsButton), findsOneWidget);
    });

    testWidgets('renders settings icon', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(
          status: DiscoveryStatus.success,
          restaurants: _testRestaurants,
        ),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders refresh button in success state', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(
          status: DiscoveryStatus.success,
          restaurants: _testRestaurants,
        ),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders initial state as loading', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders warning icon in error state', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const DiscoveryState(
          status: DiscoveryStatus.failure,
          errorMessage: 'Error',
        ),
      );

      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: mockBloc,
          child: ResultsScreen(),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
