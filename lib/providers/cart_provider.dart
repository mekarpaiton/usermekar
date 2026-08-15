import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  Map<String, CartItem> get items => {..._items};
  int get totalItem { int total=0; _items.forEach((key,item)=>total+=item.jumlah); return total; }
  double get totalHarga { double total=0; _items.forEach((key,item)=>total+=item.harga*item.jumlah); return total; }

  void addItem(String idProduk, String namaProduk, int harga, String gambar, {String? varian}) {
    final String namaVarianFix = (varian == null || varian.trim().isEmpty)? "Umum" : varian;
    final itemBaru = CartItem(idProduk: idProduk, namaProduk: namaProduk, varian: namaVarianFix, harga: harga, gambar: gambar);
    if (_items.containsKey(itemBaru.cartId)) {
      _items.update(itemBaru.cartId, (item) => CartItem(idProduk: item.idProduk, namaProduk: item.namaProduk, varian: item.varian, harga: item.harga, gambar: item.gambar, jumlah: item.jumlah+1));
    } else {
      _items.putIfAbsent(itemBaru.cartId, () => itemBaru);
    }
    notifyListeners();
  }

  void removeSingleItem(String cartId) {
    if (!_items.containsKey(cartId)) return;
    if (_items[cartId]!.jumlah>1) {
      _items.update(cartId, (item) => CartItem(idProduk: item.idProduk, namaProduk: item.namaProduk, varian: item.varian, harga: item.harga, gambar: item.gambar, jumlah: item.jumlah-1));
    } else { _items.remove(cartId); }
    notifyListeners();
  }
  void removeItem(String cartId) { _items.remove(cartId); notifyListeners(); }
  void clear() { _items={}; notifyListeners(); }
}