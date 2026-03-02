import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:randoeats/services/iap_service.dart';

part 'iap_event.dart';
part 'iap_state.dart';

/// BLoC for managing in-app purchases.
class IapBloc extends Bloc<IapEvent, IapState> {
  /// Creates an [IapBloc].
  IapBloc({IapService? iapService})
      : _iapService = iapService ?? IapService(),
        super(const IapInitial()) {
    on<IapInitialized>(_onInitialized);
    on<IapPurchaseRequested>(_onPurchaseRequested);
    on<IapRestoreRequested>(_onRestoreRequested);
    on<_IapPurchaseStatusChanged>(_onPurchaseStatusChanged);
  }

  final IapService _iapService;
  StreamSubscription<bool>? _purchaseSubscription;

  Future<void> _onInitialized(
    IapInitialized event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapLoading());

    try {
      await _iapService.initialize();

      // Listen for purchase status changes
      _purchaseSubscription = _iapService.purchaseStream.listen(
        (isPurchased) {
          add(_IapPurchaseStatusChanged(isPurchased: isPurchased));
        },
      );

      if (_iapService.isPurchased) {
        emit(const IapPurchased());
      } else {
        emit(const IapNotPurchased());
      }
    } on Exception catch (e) {
      debugPrint('IapBloc: Initialization error: $e');
      emit(IapError(e.toString()));
    }
  }

  Future<void> _onPurchaseRequested(
    IapPurchaseRequested event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapLoading());

    try {
      final started = await _iapService.purchaseAdRemoval();
      if (!started) {
        emit(const IapError('Unable to start purchase. Store not available.'));
      }
      // The purchase result will come through the stream
    } on Exception catch (e) {
      emit(IapError('Purchase error: $e'));
    }
  }

  Future<void> _onRestoreRequested(
    IapRestoreRequested event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapLoading());

    try {
      await _iapService.restorePurchases();
      // The restore result will come through the stream
      // If nothing is restored, we stay in loading briefly then check status
      if (_iapService.isPurchased) {
        emit(const IapPurchased());
      } else {
        emit(const IapNotPurchased());
      }
    } on Exception catch (e) {
      emit(IapError('Restore error: $e'));
    }
  }

  void _onPurchaseStatusChanged(
    _IapPurchaseStatusChanged event,
    Emitter<IapState> emit,
  ) {
    if (event.isPurchased) {
      emit(const IapPurchased());
    } else {
      emit(const IapNotPurchased());
    }
  }

  @override
  Future<void> close() async {
    await _purchaseSubscription?.cancel();
    await _iapService.dispose();
    return super.close();
  }
}
