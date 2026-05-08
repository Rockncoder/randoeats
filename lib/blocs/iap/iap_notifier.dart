import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/blocs/iap/iap_state.dart';
import 'package:randoeats/services/iap_service.dart';

/// Riverpod provider for in-app purchases.
final iapProvider =
    NotifierProvider<IapNotifier, IapState>(IapNotifier.new);

/// Notifier for managing in-app purchases.
class IapNotifier extends Notifier<IapState> {
  /// Creates an [IapNotifier].
  IapNotifier({IapService? iapService})
      : _iapService = iapService ?? IapService();

  final IapService _iapService;
  StreamSubscription<bool>? _purchaseSubscription;

  @override
  IapState build() => const IapInitial();

  Future<void> initialize() async {
    state = const IapLoading();

    try {
      await _iapService.initialize();

      // Listen for purchase status changes
      _purchaseSubscription = _iapService.purchaseStream.listen(
        (isPurchased) {
          if (isPurchased) {
            state = const IapPurchased();
          } else {
            state = const IapNotPurchased();
          }
        },
      );

      if (_iapService.isPurchased) {
        state = const IapPurchased();
      } else {
        state = const IapNotPurchased();
      }
    } on Exception catch (e) {
      debugPrint('IapNotifier: Initialization error: $e');
      state = IapError(e.toString());
    }
  }

  Future<void> purchase() async {
    state = const IapLoading();

    try {
      final started = await _iapService.purchaseAdRemoval();
      if (!started) {
        state = const IapError(
          'Unable to start purchase. Store not available.',
        );
      }
      // The purchase result will come through the stream
    } on Exception catch (e) {
      state = IapError('Purchase error: $e');
    }
  }

  Future<void> restore() async {
    state = const IapLoading();

    try {
      await _iapService.restorePurchases();
      // The restore result will come through the stream
      // If nothing is restored, we stay in loading briefly then check status
      if (_iapService.isPurchased) {
        state = const IapPurchased();
      } else {
        state = const IapNotPurchased();
      }
    } on Exception catch (e) {
      state = IapError('Restore error: $e');
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await _iapService.dispose();
  }
}
