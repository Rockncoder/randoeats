import 'dart:async';
import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/widgets/reel_layout.dart';
import 'package:randoeats/widgets/restaurant_card.dart';
import 'package:randoeats/widgets/slot_machine_list.dart' show OnRestaurantTap;

/// A responsive, multi-reel slot machine.
///
/// The number of reels is derived from the *measured* available width
/// ([ReelLayout.columnsForWidth]) — 1 on phones, more on tablets/foldables —
/// and the reels fill the width with no leftover gutter. On a spin, all reels
/// scroll and stop one-by-one (left → right); a single random winning cell is
/// then highlighted and reported via [onSpinComplete].
class MultiReelSlotMachine extends StatefulWidget {
  /// Creates a [MultiReelSlotMachine].
  const MultiReelSlotMachine({
    required this.restaurants,
    required this.onRestaurantTap,
    required this.onSpinComplete,
    this.detailBuilder,
    this.maxColumns = 3,
    this.calmMode = false,
    super.key,
  });

  /// Restaurants to display/spin through (repeated across cells if few).
  final List<Restaurant> restaurants;

  /// Direct tap on a (non-spinning) cell. Records the selection; navigation to
  /// the detail screen is handled by the container-transform when
  /// [detailBuilder] is provided.
  final OnRestaurantTap onRestaurantTap;

  /// Builds the detail page for a tapped restaurant. When non-null, tapping a
  /// (non-winning) card morphs it into this page via an M3 container transform.
  final Widget Function(Restaurant)? detailBuilder;

  /// Called once all reels stop, with the winning restaurant.
  final OnRestaurantTap onSpinComplete;

  /// Upper bound on reel count (3 by default — fits an iPad in landscape).
  final int maxColumns;

  /// Reduced motion: skip the scrolling spin and reveal the winner directly.
  final bool calmMode;

  @override
  State<MultiReelSlotMachine> createState() => MultiReelSlotMachineState();
}

/// State for [MultiReelSlotMachine]; exposes [spin] and [isSpinning].
class MultiReelSlotMachineState extends State<MultiReelSlotMachine> {
  static const double cardHeight = 176;
  static const Duration _baseSpin = Duration(milliseconds: 2600);
  static const Duration _stagger = Duration(milliseconds: 450);

  /// How long the winner is held — expanded + announced — before the
  /// celebration/handoff fires, so the result is unmistakable.
  static const Duration _revealHold = Duration(milliseconds: 1300);

  final _random = math.Random();
  final List<GlobalKey<_ReelState>> _reelKeys = [];

  int _columns = 1;
  int _rows = 1;
  bool _isSpinning = false;
  int? _winnerColumn;
  int _stoppedCount = 0;
  String? _winnerName;
  Timer? _revealTimer;

  /// Whether a spin is in progress.
  bool get isSpinning => _isSpinning;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  int _rowsFor(double height) {
    if (!height.isFinite || height <= 0) return 4;
    // A couple extra rows beyond the viewport so each reel has travel to spin.
    return math.max(3, (height / cardHeight).ceil() + 2);
  }

  void _syncReelKeys(int columns) {
    while (_reelKeys.length < columns) {
      _reelKeys.add(GlobalKey<_ReelState>());
    }
    if (_reelKeys.length > columns) {
      _reelKeys.removeRange(columns, _reelKeys.length);
    }
  }

  /// Spins every reel; stops them left→right; reveals one winning cell.
  ///
  /// In [MultiReelSlotMachine.calmMode] the reels are placed instantly (no
  /// scrolling) and the winner is revealed directly — reduced motion.
  void spin() {
    if (_isSpinning || widget.restaurants.isEmpty) return;
    _revealTimer?.cancel();
    setState(() {
      _isSpinning = true;
      _winnerColumn = null;
      _winnerName = null;
      _stoppedCount = 0;
    });

    final winnerColumn = _random.nextInt(_columns);

    if (widget.calmMode) {
      for (var c = 0; c < _columns; c++) {
        _reelKeys[c].currentState?.placeInstantly();
      }
      _revealWinner(winnerColumn);
      return;
    }

    for (var c = 0; c < _columns; c++) {
      _reelKeys[c].currentState?.spin(
        duration: _baseSpin + _stagger * c,
        onStopped: () => _onReelStopped(winnerColumn),
      );
    }
  }

  void _onReelStopped(int winnerColumn) {
    _stoppedCount++;
    if (_stoppedCount < _columns) return;
    _revealWinner(winnerColumn);
  }

  /// Highlights and expands the winning cell, announces it to assistive
  /// tech, then hands off to [MultiReelSlotMachine.onSpinComplete].
  void _revealWinner(int winnerColumn) {
    final reels = ReelLayout.buildReels(
      widget.restaurants,
      columns: _columns,
      rows: _rows,
    );
    final landed = _reelKeys[winnerColumn].currentState?.landedIndex ?? 0;
    final winner = reels[winnerColumn][landed];

    setState(() {
      _isSpinning = false;
      _winnerColumn = winnerColumn;
      _winnerName = winner.name;
    });

    // Let the expand + live-region announcement land before the handoff.
    _revealTimer = Timer(_revealHold, () => widget.onSpinComplete(winner));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ReelLayout.columnsForWidth(
          constraints.maxWidth,
          maxColumns: widget.maxColumns,
        );
        final rows = _rowsFor(constraints.maxHeight);
        // Cache derived layout so spin() and the next build agree.
        _columns = columns;
        _rows = rows;
        _syncReelKeys(columns);

        final reels = ReelLayout.buildReels(
          widget.restaurants,
          columns: columns,
          rows: rows,
        );

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++)
                  Expanded(
                    child: _Reel(
                      key: _reelKeys[c],
                      restaurants: reels[c],
                      cardHeight: cardHeight,
                      isWinner: _winnerColumn == c,
                      dimmed: _winnerColumn != null && _winnerColumn != c,
                      spinning: _isSpinning,
                      onCardTap: widget.onRestaurantTap,
                      detailBuilder: widget.detailBuilder,
                    ),
                  ),
              ],
            ),
            // Off-screen live region so screen readers announce the winner.
            if (_winnerName != null)
              Positioned(
                left: 0,
                top: 0,
                width: 0,
                height: 0,
                child: Semantics(
                  liveRegion: true,
                  label: 'Winner: $_winnerName',
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A single vertical reel of restaurant cards with its own spin animation.
class _Reel extends StatefulWidget {
  const _Reel({
    required this.restaurants,
    required this.cardHeight,
    required this.isWinner,
    required this.dimmed,
    required this.spinning,
    required this.onCardTap,
    this.detailBuilder,
    super.key,
  });

  final List<Restaurant> restaurants;
  final double cardHeight;
  final bool isWinner;
  final bool dimmed;
  final bool spinning;
  final OnRestaurantTap onCardTap;
  final Widget Function(Restaurant)? detailBuilder;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final AnimationController _controller;
  Animation<double>? _animation;

  int landedIndex = 0;

  /// While spinning, the reel renders a long repeating strip so the scroll can
  /// run monotonically without ever hitting the end (no wrap/pause). 0 until the
  /// first spin; falls back to the finite length in [build].
  int _spinItemCount = 0;

  @override
  void initState() {
    super.initState();
    // Create eagerly while the element is active. A lazy `late` initializer
    // would otherwise run inside dispose() for reels that never spin, doing an
    // ancestor (TickerMode) lookup on a deactivated element → crash.
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(_Reel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the spin ends the list returns to its finite length; pin the winner
    // at the top of that finite list (the strip had it at the top already, so
    // this is visually seamless).
    if (oldWidget.spinning && !widget.spinning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final maxExtent = _scroll.position.maxScrollExtent;
        _scroll.jumpTo((landedIndex * widget.cardHeight).clamp(0.0, maxExtent));
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Places this reel at a random cell instantly, with no animation.
  ///
  /// Used by calm (reduced-motion) mode.
  void placeInstantly() {
    if (widget.restaurants.isEmpty) return;
    landedIndex = math.Random().nextInt(widget.restaurants.length);
    if (_scroll.hasClients) {
      final maxExtent = _scroll.position.maxScrollExtent;
      _scroll.jumpTo((landedIndex * widget.cardHeight).clamp(0, maxExtent));
    }
  }

  /// Spins this reel for [duration], landing a random cell at the top.
  void spin({required Duration duration, required VoidCallback onStopped}) {
    final n = widget.restaurants.length;
    if (n == 0) {
      onStopped();
      return;
    }
    landedIndex = math.Random().nextInt(n);

    // Spin a consistent visual distance regardless of how many cells the column
    // has (so 1 result spins as smoothly as 12), landing exactly on a card
    // boundary with the winning cell at the top.
    const minTravelCells = 24;
    final loops = math.max(3, (minTravelCells / n).ceil());
    final endIndex = loops * n + landedIndex;
    final target = endIndex * widget.cardHeight;

    // Repeating strip long enough that the monotonic scroll never reaches the
    // end — no modulo wrap, no clamp pause. Read by [build].
    _spinItemCount = endIndex + n + 4;

    if (_scroll.hasClients) _scroll.jumpTo(0);
    _controller
      ..duration = duration
      ..reset();
    _animation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller, curve: const _SpinCurve()),
    )..addListener(_tick);

    void statusListener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      _animation?.removeListener(_tick);
      _controller.removeStatusListener(statusListener);
      // The winner is already at the top (offset == target). Re-pinning on the
      // finite list happens in didUpdateWidget once `spinning` flips false.
      onStopped();
    }

    _controller.addStatusListener(statusListener);
    unawaited(_controller.forward());
  }

  void _tick() {
    if (!_scroll.hasClients) return;
    final maxExtent = _scroll.position.maxScrollExtent;
    // Monotonic, seamless scroll. The strip is long enough that we never reach
    // the end, so there is no wrap and no pause; clamp is only a safety net.
    _scroll.jumpTo(_animation!.value.clamp(0.0, maxExtent));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.dimmed ? 0.35 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: widget.isWinner
              ? Border.all(color: GoogieColors.coral, width: 3)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.builder(
          key: const ValueKey('reel_list'),
          controller: _scroll,
          physics: widget.spinning
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          // Extra bottom padding so the last card can scroll clear of the
          // floating spin badge that hovers over the bottom of the list.
          padding: const EdgeInsets.only(top: 4, bottom: 120),
          // Finite list of options when idle; a long repeating strip while
          // spinning so the scroll loops seamlessly.
          itemCount: widget.spinning && _spinItemCount > 0
              ? _spinItemCount
              : widget.restaurants.length,
          itemBuilder: (context, index) {
            final n = widget.restaurants.length;
            final restaurant = widget.restaurants[index % n];
            final isWinnerCell =
                widget.isWinner && !widget.spinning && index == landedIndex;
            // Non-winning cells morph into the detail page (M3 container
            // transform). The winner keeps its Hero for the celebration flight.
            final useContainer =
                !widget.spinning &&
                !isWinnerCell &&
                widget.detailBuilder != null;

            RestaurantCard cardWith(VoidCallback onTap) => RestaurantCard(
              key: ValueKey('reel_cell_${restaurant.placeId}_$index'),
              restaurant: restaurant,
              index: index,
              // Only the unique winning cell anchors the Hero flight into
              // the detail screen; repeated cells leave it null.
              heroTag: isWinnerCell
                  ? restaurantPhotoHeroTag(restaurant.placeId)
                  : null,
              onTap: onTap,
            );

            final card = useContainer
                ? OpenContainer<void>(
                    tappable: false,
                    transitionType: ContainerTransitionType.fadeThrough,
                    transitionDuration: const Duration(milliseconds: 420),
                    closedColor: Colors.transparent,
                    openColor: Theme.of(context).scaffoldBackgroundColor,
                    closedElevation: 0,
                    openElevation: 0,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    closedBuilder: (ctx, open) => cardWith(() {
                      widget.onCardTap(restaurant);
                      open();
                    }),
                    openBuilder: (ctx, _) => widget.detailBuilder!(restaurant),
                  )
                : cardWith(
                    widget.spinning
                        ? () {}
                        : () => widget.onCardTap(restaurant),
                  );

            final cell = Stack(
              children: [
                card,
                if (isWinnerCell)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: GoogieColors.mustard,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            // The winning cell pulses (shrink + grow) with a subtle shake so
            // the chosen card is unmistakable before the detail screen opens.
            return isWinnerCell ? _WinnerPulse(child: cell) : cell;
          },
        ),
      ),
    );
  }
}

/// Attention animation for the winning cell: a repeating shrink↔grow pulse with
/// a subtle rocking shake, so the chosen card stands out before the detail
/// screen opens.
class _WinnerPulse extends StatefulWidget {
  const _WinnerPulse({required this.child});

  final Widget child;

  @override
  State<_WinnerPulse> createState() => _WinnerPulseState();
}

class _WinnerPulseState extends State<_WinnerPulse>
    with SingleTickerProviderStateMixin {
  // A finite burst (~3 shrink/grow pulses) that decays to rest, so it reads as
  // a clear "this is your pick!" and still settles (no perpetual animation).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final v = _controller.value;
        final decay = 1 - v; // fade the emphasis out toward rest
        final osc = math.sin(v * math.pi * 2 * 3); // 3 grow/shrink cycles
        final scale = 1 + 0.11 * osc * decay;
        final angle = 0.03 * osc * decay; // subtle rocking shake
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// Smooth trapezoidal spin easing: ramp up (accelerate) → cruise at full speed
/// → ramp down (decelerate) to a stop. Velocity is continuous (no jerks), and
/// the deceleration phase is longer than the acceleration for a satisfying
/// slot-machine slowdown. Position is normalized so transform(1) == 1.
class _SpinCurve extends Curve {
  const _SpinCurve();

  static const double _ta = 0.25; // acceleration ends
  static const double _tb = 0.6; // deceleration begins
  // Peak velocity that makes the integral (total distance) equal 1.
  static const double _vMax = 1 / (_ta / 2 + (_tb - _ta) + (1 - _tb) / 2);

  @override
  double transformInternal(double t) {
    if (t < _ta) {
      // Accelerating: area under a linearly rising velocity.
      return _vMax * t * t / (2 * _ta);
    }
    if (t < _tb) {
      // Cruising at _vMax.
      return _vMax * (_ta / 2) + _vMax * (t - _ta);
    }
    // Decelerating: linearly falling velocity to 0 at t == 1.
    final d = t - _tb;
    const dd = 1 - _tb;
    return _vMax * (_ta / 2) +
        _vMax * (_tb - _ta) +
        _vMax * (d - d * d / (2 * dd));
  }
}
