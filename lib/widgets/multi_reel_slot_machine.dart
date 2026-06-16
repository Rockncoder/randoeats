import 'dart:async';
import 'dart:math' as math;

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
    this.maxColumns = 3,
    super.key,
  });

  /// Restaurants to display/spin through (repeated across cells if few).
  final List<Restaurant> restaurants;

  /// Direct tap on a (non-spinning) cell.
  final OnRestaurantTap onRestaurantTap;

  /// Called once all reels stop, with the winning restaurant.
  final OnRestaurantTap onSpinComplete;

  /// Upper bound on reel count (3 by default — fits an iPad in landscape).
  final int maxColumns;

  @override
  State<MultiReelSlotMachine> createState() => MultiReelSlotMachineState();
}

/// State for [MultiReelSlotMachine]; exposes [spin] and [isSpinning].
class MultiReelSlotMachineState extends State<MultiReelSlotMachine> {
  static const double cardHeight = 176;
  static const Duration _baseSpin = Duration(milliseconds: 2600);
  static const Duration _stagger = Duration(milliseconds: 450);

  final _random = math.Random();
  final List<GlobalKey<_ReelState>> _reelKeys = [];

  int _columns = 1;
  int _rows = 1;
  bool _isSpinning = false;
  int? _winnerColumn;
  int _stoppedCount = 0;

  /// Whether a spin is in progress.
  bool get isSpinning => _isSpinning;

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
  void spin() {
    if (_isSpinning || widget.restaurants.isEmpty) return;
    setState(() {
      _isSpinning = true;
      _winnerColumn = null;
      _stoppedCount = 0;
    });

    final winnerColumn = _random.nextInt(_columns);
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
    });
    widget.onSpinComplete(winner);
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

        return Row(
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
    super.key,
  });

  final List<Restaurant> restaurants;
  final double cardHeight;
  final bool isWinner;
  final bool dimmed;
  final bool spinning;
  final OnRestaurantTap onCardTap;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final AnimationController _controller;
  Animation<double>? _animation;

  int landedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Create eagerly while the element is active. A lazy `late` initializer
    // would otherwise run inside dispose() for reels that never spin, doing an
    // ancestor (TickerMode) lookup on a deactivated element → crash.
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Spins this reel for [duration], landing a random cell at the top.
  void spin({required Duration duration, required VoidCallback onStopped}) {
    if (widget.restaurants.isEmpty) {
      onStopped();
      return;
    }
    landedIndex = math.Random().nextInt(widget.restaurants.length);

    final cycle = widget.restaurants.length * widget.cardHeight;
    final target = (cycle * 3) + (landedIndex * widget.cardHeight);

    if (_scroll.hasClients) _scroll.jumpTo(0);
    _controller
      ..duration = duration
      ..reset();
    _animation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller, curve: _SlotMachineCurve()),
    )..addListener(_tick);

    void statusListener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      _animation?.removeListener(_tick);
      _controller.removeStatusListener(statusListener);
      if (_scroll.hasClients) {
        final maxExtent = _scroll.position.maxScrollExtent;
        _scroll.jumpTo((landedIndex * widget.cardHeight).clamp(0, maxExtent));
      }
      onStopped();
    }

    _controller.addStatusListener(statusListener);
    unawaited(_controller.forward());
  }

  void _tick() {
    if (!_scroll.hasClients) return;
    final maxExtent = _scroll.position.maxScrollExtent;
    final wrapped = _animation!.value % (maxExtent + widget.cardHeight);
    _scroll.jumpTo(wrapped.clamp(0, maxExtent));
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: widget.restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = widget.restaurants[index];
            final isWinnerCell =
                widget.isWinner && index == landedIndex && !widget.spinning;
            return Stack(
              children: [
                RestaurantCard(
                  key: ValueKey('reel_cell_${restaurant.placeId}_$index'),
                  restaurant: restaurant,
                  index: index,
                  onTap: widget.spinning
                      ? () {}
                      : () => widget.onCardTap(restaurant),
                ),
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
          },
        ),
      ),
    );
  }
}

/// Slot-machine easing: quick start, full speed, decelerate to a stop.
class _SlotMachineCurve extends Curve {
  @override
  double transform(double t) {
    if (t < 0.1) return Curves.easeIn.transform(t * 10) * 0.1;
    if (t < 0.6) return 0.1 + (t - 0.1) * (0.6 / 0.5);
    final localT = (t - 0.6) / 0.4;
    return 0.7 + Curves.easeOutCubic.transform(localT) * 0.3;
  }
}
