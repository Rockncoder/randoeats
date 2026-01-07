import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/counter/counter.dart';
import 'package:randoeats/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: GoogieTheme.light,
      darkTheme: GoogieTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CounterPage(),
    );
  }
}
