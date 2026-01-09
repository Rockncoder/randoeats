import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/widgets/widgets.dart';

/// A callback for when an item is tapped in the list.
typedef OnRestaurantTap = void Function(Restaurant restaurant);

/// A slot machine-style animated list of restaurants.
///
/// Animates through restaurant cards like a slot machine when triggered.
class SlotMachineList extends StatefulWidget {
  /// Creates a [SlotMachineList].
  const SlotMachineList({
    required this.restaurants,
    required this.onRestaurantTap,
    required this.onSpinComplete,
    super.key,
  });

  /// The list of restaurants to display and spin through.
  final List<Restaurant> restaurants;

  /// Callback when a restaurant card is tapped directly.
  final OnRestaurantTap onRestaurantTap;

  /// Callback when the spin animation completes with the winning restaurant.
  final OnRestaurantTap onSpinComplete;

  @override
  State<SlotMachineList> createState() => SlotMachineListState();
}

/// State for [SlotMachineList] that exposes the spin method.
class SlotMachineListState extends State<SlotMachineList>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  bool _isSpinning = false;
  int _winnerIndex = 0;
  final _random = math.Random();

  // Card dimensions for calculating scroll positions
  // Card: 80px photo + 24px padding + ~72px content = ~176px + 8px margin
  static const double _cardHeight = 176;
  static const double _cardSpacing = 8;
  static const double _totalCardHeight = _cardHeight + _cardSpacing;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Remove the listener to prevent issues on next spin
        _spinAnimation.removeListener(_updateScroll);

        // Ensure winner is at the top after animation
        final winnerPosition = _winnerIndex * _totalCardHeight;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            winnerPosition.clamp(0, _scrollController.position.maxScrollExtent),
          );
        }

        setState(() {
          _isSpinning = false;
        });
        widget.onSpinComplete(widget.restaurants[_winnerIndex]);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  /// Starts the slot machine spin animation.
  void spin() {
    if (_isSpinning || widget.restaurants.isEmpty) return;

    setState(() {
      _isSpinning = true;
      // Pick a random winner
      _winnerIndex = _random.nextInt(widget.restaurants.length);
    });

    // Calculate the target scroll position
    // We want to scroll through list multiple times before landing on winner
    final fullCycleLength = widget.restaurants.length * _totalCardHeight;
    const numCycles = 3; // Number of full cycles before stopping
    final winnerPosition = _winnerIndex * _totalCardHeight;
    final targetScroll = (numCycles * fullCycleLength) + winnerPosition;

    // Reset scroll position
    _scrollController.jumpTo(0);

    // Create custom easing animation
    _spinAnimation = Tween<double>(
      begin: 0,
      end: targetScroll,
    ).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: _SlotMachineCurve(),
      ),
    );

    _spinAnimation.addListener(_updateScroll);
    unawaited(_spinController.forward(from: 0));
  }

  void _updateScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final scrollValue = _spinAnimation.value % (maxScroll + _totalCardHeight);
      _scrollController.jumpTo(scrollValue.clamp(0, maxScroll));
    }
  }

  /// Whether the slot machine is currently spinning.
  bool get isSpinning => _isSpinning;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Restaurant list
        ListView.builder(
          controller: _scrollController,
          physics:
              _isSpinning ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: widget.restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = widget.restaurants[index];
            return Opacity(
              opacity: _isSpinning ? 0.85 : 1.0,
              child: RestaurantCard(
                restaurant: restaurant,
                index: index,
                onTap: _isSpinning
                    ? () {}
                    : () => widget.onRestaurantTap(restaurant),
              ),
            );
          },
        ),
        // Gradient overlay at bottom (for visual polish)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    GoogieColors.cream.withValues(alpha: 0.9),
                    GoogieColors.cream,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Winner highlight during spin
        if (_isSpinning)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    GoogieColors.mustard,
                    GoogieColors.coral,
                    GoogieColors.mustard,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

}

/// Custom curve for slot machine animation.
///
/// Starts fast, maintains speed, then decelerates with a slight bounce.
class _SlotMachineCurve extends Curve {
  @override
  double transform(double t) {
    // Phase 1: Quick acceleration (0-0.1)
    // Phase 2: Full speed (0.1-0.6)
    // Phase 3: Deceleration with slight bounce (0.6-1.0)

    if (t < 0.1) {
      // Ease in
      return Curves.easeIn.transform(t * 10) * 0.1;
    } else if (t < 0.6) {
      // Linear full speed
      return 0.1 + (t - 0.1) * (0.6 / 0.5);
    } else {
      // Ease out with slight overshoot
      final localT = (t - 0.6) / 0.4;
      final eased = Curves.easeOutCubic.transform(localT);
      return 0.7 + eased * 0.3;
    }
  }
}
