import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart_item.dart'; // ← UDAH BENER INI

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  CartProvider() {
    loadCart();
  }

  Map<String, CartItem> get items => {..._items};
  int get totalItem => _items.values.fold(0, (sum, item) => sum + item.jumlah);
  int get totalHarga => _items.values.fold(0, (sum, item) => sum + (item.harga * item.jumlah));

  void addItem(String id, String nama, int harga, String gambar) {
    if (_items.containsKey(id)) {
      _items.update(id, (item) => CartItem(
        id: item.id, nama: item.nama, harga: item.harga,
        gambar: item.gambar, jumlah: item.jumlah + 1,
      ));
    } else {
      _items.putIfAbsent(id, () => CartItem(id: id, nama: nama, harga: harga, gambar: gambar));
    }
    notifyListeners();
    saveCart();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
    saveCart();
  }

  void kurangItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.jumlah > 1) {
      _items.update(id, (item) => CartItem(
        id: item.id, nama: item.nama, harga: item.harga,
        gambar: item.gambar, jumlah: item.jumlah - 1,
      ));
    } else {
      _items.remove(id);
    }
    notifyListeners();
    saveCart();
  }

  void tambahItem(String id) {
    _items.update(id, (item) => CartItem(
      id: item.id, nama: item.nama, harga: item.harga,
      gambar: item.gambar, jumlah: item.jumlah + 1,
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
        jumlah: itemData['jumlah'],
        harga: itemData['harga'],
        gambar: itemData['gambar'],
      );
    });

    _items = loadedCart;
    notifyListeners();
  }
}