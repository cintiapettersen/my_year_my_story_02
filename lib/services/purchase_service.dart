import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService extends ChangeNotifier {

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  PurchaseService() {
    init();
  }

  Future<void> _restorePurchases() async {
  try {
    if (kDebugMode) {
      debugPrint("🔄 RESTORING PURCHASES...");
    }

    await _inAppPurchase.restorePurchases();

  } catch (e) {
    if (kDebugMode) {
      debugPrint("❌ ERRO AO RESTAURAR COMPRAS: $e");
    }
  }
}

  bool _initialized = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  static const String monthlyId =
      'com.myyear.myyearmystory.premium_monthly';
  static const String yearlyId =
      'com.myyear.myyearmystory.premium_yearly';

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> init() async {
    if (_initialized) return;

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (kDebugMode) debugPrint("STORE AVAILABLE: $available");

      if (!available) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final Set<String> productIds = {
        monthlyId,
        yearlyId,
      };

      if (kDebugMode) debugPrint("QUERYING PRODUCTS: $productIds");

      final response =
    await _inAppPurchase.queryProductDetails(productIds);

if (kDebugMode) {
  debugPrint("🔎 PRODUCT IDS ENVIADOS: $productIds");
  debugPrint("🔎 PRODUTOS ENCONTRADOS: ${response.productDetails.length}");
  debugPrint("🔎 PRODUTOS NÃO ENCONTRADOS: ${response.notFoundIDs}");

  for (final ProductDetails product in response.productDetails) {
    debugPrint("🛒 PRODUTO ENCONTRADO → ${product.id}");
    debugPrint("💰 PREÇO → ${product.price} | raw:${product.rawPrice}");
  }
}

/// Filtrar apenas os produtos que realmente usamos
final List<ProductDetails> loadedProducts = [];

for (final ProductDetails product in response.productDetails) {

  if ((product.id == monthlyId || product.id == yearlyId) && product.rawPrice > 0) {

    loadedProducts.add(product);

    if (kDebugMode) {
      debugPrint("✅ PRODUTO ACEITO → ${product.id} | ${product.price}");
    }

  } else {

    if (kDebugMode) {
      debugPrint("⛔ PRODUTO IGNORADO → ${product.id} | raw:${product.rawPrice}");
    }

  }
}
_products = loadedProducts;

/// Log final para confirmar os planos carregados
if (kDebugMode) {
  debugPrint("📦 PLANOS CARREGADOS NO APP:");
  for (final p in _products) {
    debugPrint("➡ ${p.id} | ${p.price}");
  }
}

if (response.notFoundIDs.isNotEmpty) {
  if (kDebugMode) {
    debugPrint("⚠️ PRODUTOS NÃO ENCONTRADOS: ${response.notFoundIDs}");
  }
}

      /// NOTE:
      /// Do not filter by `rawPrice`. For subscriptions with free trials or
      /// intro phases, some stores can report 0 in the first pricing phase.
      /// Filtering would make products disappear and prices show as "...".
      

for (final ProductDetails product in response.productDetails) {
  if (product.id == monthlyId || product.id == yearlyId) {
    loadedProducts.add(product);
  }
}

_products = loadedProducts;

      /// LOG DETALHADO
      for (var p in _products) {
        if (kDebugMode) {
          debugPrint("PRODUCT LOADED → ${p.id} | ${p.price} | raw:${p.rawPrice}");
        }
      }

      _subscription ??= _inAppPurchase.purchaseStream.listen(
        _listenToPurchaseUpdated,
        onDone: () {
          if (kDebugMode) debugPrint("PURCHASE STREAM CLOSED");
        },
        onError: (error) {
          if (kDebugMode) debugPrint("PURCHASE STREAM ERROR: $error");
        },
      );
      await _restorePurchases();
    } catch (e) {
      debugPrint("Erro ao carregar produtos: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PRODUTO MENSAL

  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere((p) => p.id == monthlyId);
    } catch (_) {
      return null;
    }
  }

  /// PRODUTO ANUAL

  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere((p) => p.id == yearlyId);
    } catch (_) {
      return null;
    }
  }

  /// COMPRA MENSAL

  Future<void> buyMonthly() async {
    final product = monthlyProduct;

    if (product == null) {
      if (kDebugMode) debugPrint("Monthly product not found");
      return;
    }

    final purchaseParam =
        PurchaseParam(productDetails: product);

    if (kDebugMode) debugPrint("STARTING MONTHLY PURCHASE");

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  /// COMPRA ANUAL

  Future<void> buyYearly() async {
    final product = yearlyProduct;

    if (product == null) {
      if (kDebugMode) debugPrint("Yearly product not found");
      return;
    }

    final purchaseParam =
        PurchaseParam(productDetails: product);

    if (kDebugMode) debugPrint("STARTING YEARLY PURCHASE");

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  /// RESTAURAR COMPRAS

  Future<void> restorePurchases() async {
    if (kDebugMode) debugPrint("RESTORING PURCHASES");

    await _inAppPurchase.restorePurchases();
  }

  /// LISTENER DE COMPRAS

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (kDebugMode) {
        debugPrint("PURCHASE UPDATE: ${purchaseDetails.status}");
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
          if (kDebugMode) debugPrint("PURCHASE COMPLETED");

          _isPremium = true;
          notifyListeners();

          break;

        case PurchaseStatus.restored:
          if (kDebugMode) debugPrint("PURCHASE RESTORED");

          _isPremium = true;
          notifyListeners();

          break;

        case PurchaseStatus.error:
          if (kDebugMode) {
            debugPrint("PURCHASE ERROR: ${purchaseDetails.error}");
          }
          break;

        case PurchaseStatus.pending:
          if (kDebugMode) debugPrint("PURCHASE PENDING");
          break;

        case PurchaseStatus.canceled:
          if (kDebugMode) debugPrint("PURCHASE CANCELED");
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
