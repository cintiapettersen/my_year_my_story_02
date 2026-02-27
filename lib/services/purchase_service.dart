import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/profile_service.dart';

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  static const String monthlyId =
      'com.myyear.myyearmystory.premium.monthly';
  static const String yearlyId =
      'com.myyear.myyearmystory.premium.yearly';

  final Set<String> _productIds = {monthlyId, yearlyId};

  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isPremium = false;
  bool isLoading = true;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PurchaseService() {
    _initialize();
  }

  Future<void> _initialize() async {

    notifyListeners();

    // 🔹 2. Verifica se StoreKit está disponível
    isAvailable = await _inAppPurchase.isAvailable();

    if (!isAvailable) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // 🔹 3. Busca produtos
    final response =
        await _inAppPurchase.queryProductDetails(_productIds);

    products = response.productDetails;

    // 🔹 4. Escuta compras
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {},
    );

    // 🔹 5. Restaura compras automaticamente
    await _inAppPurchase.restorePurchases();

    isLoading = false;
    notifyListeners();
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          break;

        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.canceled:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

 Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails) async {

  if (_productIds.contains(purchaseDetails.productID)) {

    isPremium = true;

  

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_premium': true})
          .eq('id', user.id);

      // 🔥 FORÇA RELOAD DO PROFILE
      await profileService.load();
    }

    notifyListeners();
  }
}

  ProductDetails? get monthlyProduct {
    try {
      return products.firstWhere((p) => p.id == monthlyId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get yearlyProduct {
    try {
      return products.firstWhere((p) => p.id == yearlyId);
    } catch (_) {
      return null;
    }
  }

  Future<void> buyMonthly() async {
    final product = monthlyProduct;
    if (product == null) return;

    final purchaseParam =
        PurchaseParam(productDetails: product);

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> buyYearly() async {
    final product = yearlyProduct;
    if (product == null) return;

    final purchaseParam =
        PurchaseParam(productDetails: product);

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
