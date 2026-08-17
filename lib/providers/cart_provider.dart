import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  Map<String, CartItem> get items => {..._items};

  int get totalItem {
    int total=0;
    _items.forEach((k,v)=>total+=v.jumlah);
    return total;
  }
  int get totalHarga {
    int total=0;
    _items.forEach((k,v)=>total+=v.harga * v.jumlah);
    return total;
  }

  void addItem(String idProduk, String namaProduk, int harga, String gambar, {String? varian}) {
    final fixVarian = (varian==null || varian.trim().isEmpty)? "Umum" : varian;
    final baru = CartItem(idProduk: idProduk, namaProduk: namaProduk, varian: fixVarian, harga: harga, gambar: gambar, jumlah: 1);
    if (_items.containsKey(baru.cartId)) {
      _items[baru.cartId]!.jumlah++;
    } else {
      _items[baru.cartId] = baru;
    }
    notifyListeners();
  }

  // buat kompatibel sama kode lama yang manggil tambah(produk Map)
  void tambah(dynamic produk) {
    try {
      String id = produk['id'].toString();
      String nama = produk['nama'].toString();
      int harga = int.tryParse('${produk['harga_umum']??produk['harga']??0}')??0;
      String foto = produk['foto']??'';
      addItem(id, nama, harga, foto);
    } catch(e){ print(e); }
  }

  void kurangi(dynamic idOrCartId) {
    String key = idOrCartId.toString();
    String? target;
    if (_items.containsKey(key)) target=key;
    else _items.forEach((k,v){ if(v.idProduk==key) target=k; });
    if (target!=null) {
      if (_items[target]!.jumlah>1) _items[target]!.jumlah--;
      else _items.remove(target);
      notifyListeners();
    }
  }

  void setQty(dynamic idOrCartId, int newQty) {
    String key = idOrCartId.toString();
    String? target;
    if (_items.containsKey(key)) target=key;
    else _items.forEach((k,v){ if(v.idProduk==key) target=k; });
    if (target==null) return;
    if (newQty<=0) _items.remove(target);
    else _items[target]!.jumlah = newQty;
    notifyListeners();
  }

  void removeItem(String cartId){ _items.remove(cartId); notifyListeners(); }
  void clear(){ _items={}; notifyListeners(); }
}