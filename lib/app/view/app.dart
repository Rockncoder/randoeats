import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/l10n/l10n.dart';
import 'package:randoeats/screens/screens.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiscoveryBloc(),
      child: MaterialApp(
        theme: GoogieTheme.light,
        darkTheme: GoogieTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [
          FirebaseAnalyticsObserver(
            analytics: FirebaseAnalytics.instance,
          ),
        ],
        home: const ResultsScreen(),
      ),
    );
  }
}
