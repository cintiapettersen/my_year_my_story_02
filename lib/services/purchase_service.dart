import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  final Set<String> _productIds = {
    'com.myyear.myyearmystory.premium.monthly',
    'com.myyear.myyearmystory.premium.yearly',
  };

  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isPremium = false;
  bool isLoading = true;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PurchaseService() {
    _initialize();
  }

  Future<void> _initialize() async {
    isAvailable = await _inAppPurchase.isAvailable();

    if (!isAvailable) {
      isLoading = false;
      notifyListeners();
      return;
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint("Erro ao buscar produtos: ${response.error}");
    }

    products = response.productDetails;

    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint("Erro na purchaseStream: $error");
      },
    );

    isLoading = false;
    notifyListeners();
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _deliverProduct(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("Erro na compra: ${purchaseDetails.error}");
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    if (_productIds.contains(purchaseDetails.productID)) {
      isPremium = true;
      notifyListeners();
    }
  }

  ProductDetails? get monthlyProduct {
    try {
      return products.firstWhere(
        (product) =>
            product.id ==
            'com.myyear.myyearmystory.premium.monthly',
      );
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get yearlyProduct {
    try {
      return products.firstWhere(
        (product) =>
            product.id ==
            'com.myyear.myyearmystory.premium.yearly',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> buyMonthly() async {
    final product = monthlyProduct;
    if (product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> buyYearly() async {
    final product = yearlyProduct;
    if (product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
