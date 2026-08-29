import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing Google Play Billing lifecycle.
///
/// Features:
/// - Connects to Google Play Billing via the `in_app_purchase` package.
/// - Loads active product details (annual, monthly, lifetime).
/// - Launches native Google Play purchase & subscription bottom sheets.
/// - Listens for real-time purchase updates, automatically acknowledging transactions.
/// - Supports purchase restoration and auto-updates Riverpod state.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs defined in Google Play Console
  static const String annualProductId = 'mindwipe_pro_annual';
  static const String monthlyProductId = 'mindwipe_pro_monthly';
  static const String lifetimeProductId = 'mindwipe_pro_lifetime';

  static const Set<String> productIds = {
    annualProductId,
    monthlyProductId,
    lifetimeProductId,
  };

  /// Loaded products directly from Google Play Store
  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isPurchasing = false;

  /// Callback notified whenever Pro status is confirmed or updated
  void Function(bool isPremium)? onPremiumChanged;

  /// Error callback for showing user-friendly toasts or dialogs
  void Function(String message)? onError;

  /// Initialize Google Play Billing connection on app startup.
  Future<void> initialize() async {
    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        debugPrint('[PurchaseService] Google Play Billing unavailable on this device.');
        return;
      }

      // Listen to real-time purchase stream
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('[PurchaseService] Purchase stream error: $error');
          onError?.call('Billing connection error. Please check Play Store.');
        },
      );

      // Query product details from Google Play
      await refreshProducts();
    } catch (e) {
      debugPrint('[PurchaseService] Initialization error: $e');
    }
  }

  /// Refreshes product details from Google Play.
  Future<void> refreshProducts() async {
    if (!isAvailable) return;
    try {
      final response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        debugPrint('[PurchaseService] Product query error: ${response.error}');
      }
      products = response.productDetails;
      debugPrint('[PurchaseService] Loaded ${products.length} products from Google Play.');
    } catch (e) {
      debugPrint('[PurchaseService] refreshProducts failed: $e');
    }
  }

  /// Launches the native Google Play purchase flow for a product.
  Future<bool> buyProduct(String productId) async {
    if (!isAvailable) {
      onError?.call('Google Play Billing is not available on this device.');
      return false;
    }

    ProductDetails? product;
    try {
      product = products.firstWhere((p) => p.id == productId);
    } catch (_) {
      // Product not loaded yet, try refreshing once
      await refreshProducts();
      try {
        product = products.firstWhere((p) => p.id == productId);
      } catch (_) {
        onError?.call('Product details not available yet. Please check your internet connection.');
        return false;
      }
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    isPurchasing = true;

    try {
      if (productId == lifetimeProductId) {
        // Non-consumable lifetime unlock
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Recurring subscription (Annual with trial, or Monthly)
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      isPurchasing = false;
      debugPrint('[PurchaseService] buyProduct failed: $e');
      onError?.call('Could not initiate purchase: $e');
      return false;
    }
  }

  /// Restores past purchases (e.g., when reinstalling or changing phones).
  Future<void> restorePurchases() async {
    if (!isAvailable) {
      onError?.call('Google Play Billing is not available.');
      return;
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[PurchaseService] restorePurchases failed: $e');
      onError?.call('Failed to restore purchases: $e');
    }
  }

  /// Processes transaction updates from Google Play.
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Validated purchase or restored active subscription
          await _deliverProduct(purchaseDetails);
          break;

        case PurchaseStatus.error:
          isPurchasing = false;
          debugPrint('[PurchaseService] Purchase error: ${purchaseDetails.error?.message}');
          onError?.call(purchaseDetails.error?.message ?? 'Purchase was cancelled or failed.');
          break;

        case PurchaseStatus.pending:
          // Waiting for user to complete payment at external vendor / banking app
          debugPrint('[PurchaseService] Purchase pending confirmation.');
          break;

        case PurchaseStatus.canceled:
          isPurchasing = false;
          debugPrint('[PurchaseService] Purchase cancelled by user.');
          break;
      }

      // Complete/Acknowledge purchase to prevent automatic Google Play refund after 3 days
      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchaseDetails);
        } catch (e) {
          debugPrint('[PurchaseService] Error completing purchase: $e');
        }
      }
    }
  }

  /// Delivers Pro features to the user upon valid purchase.
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    isPurchasing = false;
    debugPrint('[PurchaseService] Delivering Pro tier for product: ${purchaseDetails.productID}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mindwipe_is_premium', true);
    await prefs.setString('mindwipe_active_product_id', purchaseDetails.productID);

    onPremiumChanged?.call(true);
  }

  /// Helper to get formatted price string for a product ID, with default fallbacks.
  String getPriceFormatted(String productId, String fallback) {
    try {
      final product = products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (_) {
      return fallback;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
