import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<List<String>> _productsController =
      StreamController<List<String>>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _initialized = false;

  Stream<List<String>> get productTitles => _productsController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final available = await _iap.isAvailable();
    if (!available) {
      _productsController.add(['Store unavailable']);
      return;
    }

    const ids = {'premium_monthly_placeholder'};
    final response = await _iap.queryProductDetails(ids);

    if (response.productDetails.isEmpty) {
      _productsController.add(['Premium (dummy product id)']);
    } else {
      _productsController.add(
        response.productDetails
            .map((product) => '${product.title}  ${product.price}')
            .toList(),
      );
    }

    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    });
  }

  void buyPremiumPlaceholder() {
    // Placeholder only: product configuration is intentionally handled in stores later.
  }

}
