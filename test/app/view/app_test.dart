import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/screens/screens.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    testWidgets('renders ResultsScreen', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            discoveryProvider.overrideWith(
              () => DiscoveryNotifier(),
            ),
          ],
          child: const ResultsScreen(),
        ),
      );
      expect(find.byType(ResultsScreen), findsOneWidget);
    });
  });
}
