import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:randoeats/config/config.dart';
import 'package:url_launcher/url_launcher.dart';

/// About screen — shows the app identity and the current version.
///
/// Reachable from the info button on the results screen.
class AboutScreen extends StatefulWidget {
  /// Creates an [AboutScreen].
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _website = 'https://randoeats.com';
  static const _privacyUrl = 'https://tekadept.com/randoeats/privacy';
  static const _termsUrl = 'https://tekadept.com/randoeats/terms';

  String? _version;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVersion());
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    // info.version is major.minor.patch (patch tracks the build number).
    setState(() => _version = info.version);
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          key: const ValueKey('about_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/rand-o-eats-new.png',
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 8),
              Text(
                'rand-o-eats',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: GoogieColors.coral,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your atomic-age appetite assistant',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _version == null ? 'Version …' : 'Version $_version',
                key: const ValueKey('about_version'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: GoogieColors.deepTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _AboutLink(
                icon: Icons.public,
                label: 'randoeats.com',
                onTap: () => unawaited(_open(_website)),
                theme: theme,
              ),
              _AboutLink(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => unawaited(_open(_privacyUrl)),
                theme: theme,
              ),
              _AboutLink(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => unawaited(_open(_termsUrl)),
                theme: theme,
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 TekAdept',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutLink extends StatelessWidget {
  const _AboutLink({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: GoogieColors.turquoise),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: GoogieColors.turquoise,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
