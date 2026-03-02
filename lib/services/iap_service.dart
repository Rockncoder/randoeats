import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product ID for ad removal in-app purchase.
const String kAdRemovalProductId = 'randoeats_ad_removal';

/// Hive box name for IAP data.
const String _iapBoxName = 'iap';

/// Key for storing purchase status.
const String _purchasedKey = 'ad_free_purchased';

/// Service for managing in-app purchases.
///
/// Handles the ad-free non-consumable purchase. Skips initialization
/// on web (kIsWeb).
class IapService {
  /// Creates an [IapService].
  IapService({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Box<bool>? _iapBox;

  bool _isAvailable = false;
  bool _isPurchased = false;

  /// Whether the store is available.
  bool get isAvailable => _isAvailable;

  /// Whether the ad-free purchase has been made.
  bool get isPurchased => _isPurchased;

  /// Stream controller for purchase status changes.
  final _purchaseController = StreamController<bool>.broadcast();

  /// Stream of purchase status changes.
  Stream<bool> get purchaseStream => _purchaseController.stream;

  /// Initializes the IAP service.
  ///
  /// Skips on web platform. Checks local storage for existing purchase,
  /// then verifies with the store.
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('IapService: Skipping on web');
      return;
    }

    // Open Hive box for IAP persistence
    _iapBox = await Hive.openBox<bool>(_iapBoxName);

    // Check local storage first
    _isPurchased = _iapBox?.get(_purchasedKey) ?? false;
    if (_isPurchased) {
      _purchaseController.add(true);
    }

    // Check store availability
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('IapService: Store not available');
      return;
    }

    // Listen for purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error) {
        debugPrint('IapService: Purchase stream error: $error');
      },
    );
  }

  /// Initiates the ad removal purchase.
  Future<bool> purchaseAdRemoval() async {
    if (!_isAvailable) return false;

    final response = await _inAppPurchase.queryProductDetails({
      kAdRemovalProductId,
    });

    if (response.productDetails.isEmpty) {
      debugPrint('IapService: Product not found');
      return false;
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restores previous purchases.
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _inAppPurchase.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final details in purchaseDetailsList) {
      if (details.productID != kAdRemovalProductId) continue;

      switch (details.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _setPurchased(value: true);
        case PurchaseStatus.error:
          debugPrint('IapService: Purchase error: ${details.error}');
        case PurchaseStatus.pending:
          debugPrint('IapService: Purchase pending');
        case PurchaseStatus.canceled:
          debugPrint('IapService: Purchase canceled');
      }

      // Complete the purchase if pending
      if (details.pendingCompletePurchase) {
        unawaited(_inAppPurchase.completePurchase(details));
      }
    }
  }

  void _setPurchased({required bool value}) {
    _isPurchased = value;
    unawaited(_iapBox?.put(_purchasedKey, value));
    _purchaseController.add(value);
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _purchaseController.close();
  }
}
