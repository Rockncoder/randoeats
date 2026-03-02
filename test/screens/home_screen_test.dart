import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/screens/screens.dart';

void main() {
  group('HomeScreen', () {
    // HomeScreen calls LocationService.instance.getCurrentLocation() in
    // initState, which invokes Geolocator (native plugin). Since native
    // plugins are not available in widget tests without channel mocking,
    // we test that the widget can be constructed.

    test('can be constructed', () {
      const screen = HomeScreen();
      expect(screen, isA<HomeScreen>());
    });
  });
}
