import 'package:randoeats/app/app.dart';
import 'package:randoeats/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
