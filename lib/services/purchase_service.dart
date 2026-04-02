import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// 購入イベントの種別
enum PurchaseEvent { purchased, restored, error }

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const _isPremiumKey = 'is_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPremium = false;
  bool get isPremium => _isPremium || kDebugMode;

  bool _isAvailable = false;
  bool get isStoreAvailable => _isAvailable;

  ProductDetails? _monthlyProduct;
  ProductDetails? _yearlyProduct;
  ProductDetails? get monthlyProduct => _monthlyProduct;
  ProductDetails? get yearlyProduct => _yearlyProduct;

  /// 状態変更を通知するコールバック
  VoidCallback? onPremiumChanged;

  /// 購入イベントを通知するコールバック（UI側でSnackBar表示用）
  void Function(PurchaseEvent event)? onPurchaseEvent;

  Future<void> initialize() async {
    // SharedPreferencesから課金状態を復元
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_isPremiumKey) ?? false;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    // 購入ストリームを監視
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: _onDone,
      onError: _onError,
    );

    // 商品情報を取得
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({
      AppConstants.monthlyProductId,
      AppConstants.yearlyProductId,
    });

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    for (final product in response.productDetails) {
      if (product.id == AppConstants.monthlyProductId) {
        _monthlyProduct = product;
      } else if (product.id == AppConstants.yearlyProductId) {
        _yearlyProduct = product;
      }
    }
  }

  /// 月額プランを購入
  Future<bool> purchaseMonthly() async {
    if (_monthlyProduct == null) return false;
    return _purchase(_monthlyProduct!);
  }

  /// 年額プランを購入
  Future<bool> purchaseYearly() async {
    if (_yearlyProduct == null) return false;
    return _purchase(_yearlyProduct!);
  }

  Future<bool> _purchase(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// 購入を復元
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased) {
      await _setPremium(true);
      onPurchaseEvent?.call(PurchaseEvent.purchased);
    } else if (purchase.status == PurchaseStatus.restored) {
      await _setPremium(true);
      onPurchaseEvent?.call(PurchaseEvent.restored);
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchase.error}');
      onPurchaseEvent?.call(PurchaseEvent.error);
    }

    // pendingPurchaseを完了させる
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, value);
    onPremiumChanged?.call();
  }

  void _onDone() {
    _subscription?.cancel();
  }

  void _onError(Object error) {
    debugPrint('Purchase stream error: $error');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
