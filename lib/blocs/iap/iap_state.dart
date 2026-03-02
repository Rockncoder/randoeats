part of 'iap_bloc.dart';

/// States for the IAP BLoC.
sealed class IapState extends Equatable {
  const IapState();
}

/// Initial state before IAP is initialized.
class IapInitial extends IapState {
  const IapInitial();

  @override
  List<Object?> get props => [];
}

/// IAP is loading (initializing or processing purchase).
class IapLoading extends IapState {
  const IapLoading();

  @override
  List<Object?> get props => [];
}

/// Ad-free has been purchased.
class IapPurchased extends IapState {
  const IapPurchased();

  @override
  List<Object?> get props => [];
}

/// Not purchased (default/free state).
class IapNotPurchased extends IapState {
  const IapNotPurchased();

  @override
  List<Object?> get props => [];
}

/// An error occurred during IAP.
class IapError extends IapState {
  const IapError(this.message);

  /// Error description.
  final String message;

  @override
  List<Object?> get props => [message];
}
