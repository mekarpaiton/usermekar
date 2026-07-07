import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get totalItem {
    int total = 0;
    _items.forEach((key, item) => total += item.jumlah);
    return total;
  } // tutup totalItem

  double get totalHarga {
    double total = 0;
    _items.forEach((key, item) => total += item.harga * item.jumlah);
    return total;
  } // tutup totalHarga

  void addItem(
    String idProduk,
    String namaProduk,
    int harga,
    String gambar, {
    String? varian, // parameter opsional
  }) {
    // ====================================================================
    // FIX UTAMA: Jaminan jika varian null atau kosong, paksa jadi "Umum"
    // ====================================================================
    final String namaVarianFix = (varian == null || varian.trim().isEmpty) ? "Umum" : varian;

    final itemBaru = CartItem(
      idProduk: idProduk,
      namaProduk: namaProduk,
      varian: namaVarianFix, // Gunakan varian yang sudah aman
      harga: harga,
      gambar: gambar,
    ); // tutup CartItem

    // Gunakan itemBaru.cartId yang sekarang dijamin tidak akan bernilai null/rusak
    if (_items.containsKey(itemBaru.cartId)) {
      _items.update(itemBaru.cartId, (item) => CartItem(
        idProduk: item.idProduk,
        namaProduk: item.namaProduk,
        varian: item.varian,
        harga: item.harga,
        gambar: item.gambar,
        jumlah: item.jumlah + 1,
      )); // tutup CartItem update
    } else {
      _items.putIfAbsent(itemBaru.cartId, () => itemBaru);
    }
    notifyListeners();
  } // tutup addItem

  void removeSingleItem(String cartId) {
    if (!_items.containsKey(cartId)) return;
    if (_items[cartId]!.jumlah > 1) {
      _items.update(cartId, (item) => CartItem(
        idProduk: item.idProduk,
        namaProduk: item.namaProduk,
        varian: item.varian,
        harga: item.harga,
        gambar: item.gambar,
        jumlah: item.jumlah - 1,
      )); // tutup CartItem
    } else {
      _items.remove(cartId);
    }
    notifyListeners();
  } // tutup removeSingleItem

  void removeItem(String cartId) {
    _items.remove(cartId);
    notifyListeners();
  } // tutup removeItem

  void clear() {
    _items = {};
    notifyListeners();
  } // tutup clear
} // tutup CartProvider
