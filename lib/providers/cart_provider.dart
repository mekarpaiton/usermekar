import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  CartProvider() {
    loadCart();
  }

  Map<String, CartItem> get items => {..._items};
  int get totalItem => _items.values.fold(0, (sum, item) => sum + item.jumlah);
  int get totalHarga => _items.values.fold(0, (sum, item) => sum + (item.harga * item.jumlah));

  void addItem(String id, String nama, int harga, String gambar, {
    required String varian,
    required int hargaNormal,
    required int isPromo,
  }) {
    final key = '$id-$varian'; // varian beda = item beda di cart
    if (_items.containsKey(key)) {
      _items.update(key, (item) => CartItem(
        id: item.id, nama: item.nama, harga: item.harga,
        hargaNormal: item.hargaNormal, isPromo: item.isPromo,
        varian: item.varian, gambar: item.gambar, jumlah: item.jumlah + 1,
      ));
    } else {
      _items.putIfAbsent(key, () => CartItem(
        id: id, nama: nama, harga: harga, hargaNormal: hargaNormal,
        isPromo: isPromo, varian: varian, gambar: gambar,
      ));
    }
    notifyListeners();
    saveCart();
  }

  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
    saveCart();
  }

  void kurangItem(String key) {
    if (!_items.containsKey(key)) return;
    if (_items[key]!.jumlah > 1) {
      _items.update(key, (item) => CartItem(
        id: item.id, nama: item.nama, harga: item.harga,
        hargaNormal: item.hargaNormal, isPromo: item.isPromo,
        varian: item.varian, gambar: item.gambar, jumlah: item.jumlah - 1,
      ));
    } else {
      _items.remove(key);
    }
    notifyListeners();
    saveCart();
  }

  void tambahItem(String key) {
    _items.update(key, (item) => CartItem(
      id: item.id, nama: item.nama, harga: item.harga,
      hargaNormal: item.hargaNormal, isPromo: item.isPromo,
      varian: item.varian, gambar: item.gambar, jumlah: item.jumlah + 1,
    ));
    notifyListeners();
    saveCart();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    saveCart();
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = _items.map((key, item) => MapEntry(key, item.toJson()));
    prefs.setString('cartTBMEKAR', json.encode(cartData));
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('cartTBMEKAR')) return;

    final cartData = json.decode(prefs.getString('cartTBMEKAR')!) as Map<String, dynamic>;
    final loadedCart = <String, CartItem>{};

    cartData.forEach((key, itemData) {
      loadedCart[key] = CartItem(
        id: itemData['id'],
        nama: itemData['nama'],
        jumlah: itemData['qty']?? itemData['jumlah']?? 1,
        harga: itemData['harga'],
        hargaNormal: itemData['harga_normal']?? itemData['harga'],
        isPromo: itemData['is_promo']?? 0,
        varian: itemData['varian']?? 'umum',
        gambar: itemData['gambar'],
      );
    });

    _items = loadedCart;
    notifyListeners();
  }
}