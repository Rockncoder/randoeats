import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/services/services.dart';

/// The main home screen of rand-o-eats.
///
/// Displays a retro-future themed interface for discovering restaurants.
class HomeScreen extends StatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _moodController = TextEditingController();
  bool _isLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    unawaited(_checkLocation());
  }

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    final result = await LocationService.instance.getCurrentLocation();

    setState(() {
      _isLoading = false;
      switch (result) {
        case LocationSuccess():
          _locationError = null;
        case LocationPermissionDenied(isPermanent: final isPermanent):
          _locationError = isPermanent
              ? 'Location permission denied. Please enable in settings.'
              : 'Location permission required to find nearby restaurants.';
        case LocationServicesDisabled():
          _locationError = 'Please enable location services on your device.';
        case LocationError(message: final message):
          _locationError = 'Location error: $message';
      }
    });
  }

  void _onEngagePressed() {
    // TODO(phase2): Implement discovery flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scanning nearby quadrants for "${_moodController.text}"...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GoogieColors.cream,
              ),
        ),
        backgroundColor: GoogieColors.turquoise,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Logo/Title area
              _buildHeader(theme),
              const SizedBox(height: 48),
              // Greeting
              _buildGreeting(theme),
              const SizedBox(height: 32),
              // Mood input
              _buildMoodInput(theme),
              const SizedBox(height: 24),
              // Engage button
              _buildEngageButton(theme),
              const Spacer(flex: 2),
              // Location status
              if (_locationError != null || _isLoading)
                _buildLocationStatus(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App logo placeholder
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: GoogieColors.turquoise.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: GoogieColors.turquoise,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            size: 60,
            color: GoogieColors.turquoise,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'rand-o-eats',
          style: theme.textTheme.displaySmall?.copyWith(
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
        ),
      ],
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Greetings, Earthling!',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'What sustenance do you require?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMoodInput(ThemeData theme) {
    return TextField(
      controller: _moodController,
      decoration: InputDecoration(
        hintText: 'e.g., "I want tacos" or "No fast food"',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: GoogieColors.turquoise,
        ),
        suffixIcon: _moodController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _moodController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _onEngagePressed(),
    );
  }

  Widget _buildEngageButton(ThemeData theme) {
    final hasLocation = _locationError == null && !_isLoading;

    return ElevatedButton(
      onPressed: hasLocation ? _onEngagePressed : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch, size: 24),
          const SizedBox(width: 12),
          Text(
            'ENGAGE!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: GoogieColors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus(ThemeData theme) {
    if (_isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GoogieColors.turquoise,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Pinpointing your coordinates...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: GoogieColors.turquoise,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GoogieColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GoogieColors.coral.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off,
            color: GoogieColors.coral,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _locationError ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: GoogieColors.coral,
              ),
            ),
          ),
          TextButton(
            onPressed: _checkLocation,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}
