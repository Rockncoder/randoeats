import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/screens/screens.dart';

import '../../helpers/helpers.dart';

class _MockDiscoveryBloc extends Mock implements DiscoveryBloc {}

void main() {
  group('App', () {
    late _MockDiscoveryBloc bloc;

    setUp(() {
      bloc = _MockDiscoveryBloc();
      when(() => bloc.state).thenReturn(const DiscoveryState());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.isClosed).thenReturn(false);
    });

    testWidgets('renders ResultsScreen', (tester) async {
      await tester.pumpApp(
        BlocProvider<DiscoveryBloc>.value(
          value: bloc,
          child: const ResultsScreen(),
        ),
      );
      expect(find.byType(ResultsScreen), findsOneWidget);
    });
  });
}
