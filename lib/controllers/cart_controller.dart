import 'package:flutter/material.dart';
import '../services/app_database.dart';
import 'dart:convert';
import 'settings_controller.dart';

class CartController extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _discountData = {
    'total_discount': 0.0,
    'promo_count': 0,
    'promo_names': [],
  };

  List<Map<String, dynamic>> get items => _items;
  Map<String, dynamic> get discountData => _discountData;

  void addToCart(
    Product product, {
    List? options,
    String? notes,
    double? price,
  }) {
    // Check if exact same item (product + options + notes) already in cart
    final existingIndex = _items.indexWhere((item) {
      bool sameProduct = (item['product'] as Product).id == product.id;
      bool sameOptions = _compareOptions(item['selected_options'], options);
      bool sameNotes = (item['notes'] ?? '') == (notes ?? '');
      return sameProduct && sameOptions && sameNotes;
    });

    if (existingIndex != -1) {
      _items[existingIndex]['quantity']++;
    } else {
      _items.add({
        'cart_id': DateTime.now().microsecondsSinceEpoch.toString(),
        'product': product,
        'quantity': 1,
        'selected_options': options ?? [],
        'notes': notes ?? '',
        'price': price ?? product.salePrice ?? 0,
      });
    }
    
    _applyWholesalePricing();
    notifyListeners();
  }

  void _applyWholesalePricing() {
    if (!SettingsController.instance.featureGrosirEnabled.value) return;

    for (var item in _items) {
      final product = item['product'] as Product;
      if (product.wholesalePricesJson == null) continue;

      try {
        final List tiers = jsonDecode(product.wholesalePricesJson!);
        if (tiers.isEmpty) continue;

        int quantity = item['quantity'] as int;
        double effectivePrice = (product.salePrice ?? 0).toDouble();

        // Find the best tier
        for (var tier in tiers) {
          int minQty = tier['minQty'] ?? 0;
          double tierPrice = (tier['price'] ?? 0).toDouble();
          if (quantity >= minQty && minQty > 0) {
            effectivePrice = tierPrice;
          }
        }
        
        item['price'] = effectivePrice;
      } catch (_) {}
    }
  }

  void removeFromCart(String cartId) {
    final index = _items.indexWhere((item) => item['cart_id'] == cartId);
    if (index != -1) {
      if (_items[index]['quantity'] > 1) {
        _items[index]['quantity']--;
      } else {
        _items.removeAt(index);
      }
    }
    _applyWholesalePricing();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discountData = {
      'total_discount': 0.0,
      'promo_count': 0,
      'promo_names': [],
    };
    notifyListeners();
  }

  void setDiscountData(Map<String, dynamic> data) {
    _discountData = data;
    notifyListeners();
  }

  int get totalCount =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  double get totalAmount => _items.fold(0, (sum, item) {
    return sum +
        ((item['price'] as num).toDouble() * (item['quantity'] as int));
  });

  bool _compareOptions(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    final listA = List<Map<String, dynamic>>.from(a)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));
    final listB = List<Map<String, dynamic>>.from(b)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));

    for (int i = 0; i < listA.length; i++) {
      if (listA[i]['value_id'] != listB[i]['value_id']) return false;
    }
    return true;
  }
}
