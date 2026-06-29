import 'package:flutter/material.dart';
import '../cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

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
    notifyListeners(); // Ini yg bikin badge 🛒 update
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }
void kurangItem(String id) {
  if (!_items.containsKey(id)) return;
  if (_items[id]!.jumlah > 1) {
    _items.update(id, (item) => CartItem(
      id: item.id,
      nama: item.nama,
      harga: item.harga,
      gambar: item.gambar,
      jumlah: item.jumlah - 1,
    ));
  } else {
    _items.remove(id); // Kalo qty tinggal 1, hapus aja
  }
  notifyListeners();
}

void tambahItem(String id) {
  _items.update(id, (item) => CartItem(
    id: item.id,
    nama: item.nama,
    harga: item.harga,
    gambar: item.gambar,
    jumlah: item.jumlah + 1,
  ));
  notifyListeners();
}
  void clear() {
    _items.clear();
    notifyListeners();
  }
}