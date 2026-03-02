part of 'iap_bloc.dart';

/// Base class for IAP events.
sealed class IapEvent extends Equatable {
  const IapEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the IAP service.
class IapInitialized extends IapEvent {
  const IapInitialized();
}

/// Event to request a purchase.
class IapPurchaseRequested extends IapEvent {
  const IapPurchaseRequested();
}

/// Event to restore previous purchases.
class IapRestoreRequested extends IapEvent {
  const IapRestoreRequested();
}

/// Internal event when purchase status changes.
class _IapPurchaseStatusChanged extends IapEvent {
  const _IapPurchaseStatusChanged({required this.isPurchased});

  final bool isPurchased;

  @override
  List<Object?> get props => [isPurchased];
}
