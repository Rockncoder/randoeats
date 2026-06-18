import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/app/router.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/l10n/l10n.dart';
import 'package:randoeats/providers/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appTheme = ref.watch(themeProvider);
    // Point the static palette at the active theme before building the tree, so
    // every `GoogieColors.*` getter resolves to the selected theme's colors.
    GoogieColors.current = appTheme.palette;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: appTheme.data,
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
