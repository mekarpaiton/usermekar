import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  Map<String, CartItem> get items => {..._items};

  int get totalItem {
    int total=0;
    _items.forEach((key,item)=>total+=item.jumlah);
    return total;
  }

  // totalHarga jadi int biar enak di checkout
  int get totalHarga {
    int total=0;
    _items.forEach((key,item)=>total+=item.harga*item.jumlah);
    return total;
  }

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

  // buat kompatibilitas sama kode checkout lama yang manggil tambah(produk)
  void tambah(dynamic produk) {
    try {
      String id = produk['id'].toString();
      String nama = produk['nama'].toString();
      int harga = 0;
      try { harga = int.parse('${produk['harga_umum']?? produk['harga']?? 0}'); } catch(_){ harga = produk['harga'] is int? produk['harga'] : 0; }
      String foto = produk['foto']??'';
      addItem(id, nama, harga, foto);
    } catch(e) {
      print('tambah error $e');
    }
  }

  void removeSingleItem(String cartId) {
    if (!_items.containsKey(cartId)) return;
    if (_items[cartId]!.jumlah>1) {
      _items.update(cartId, (item) => CartItem(idProduk: item.idProduk, namaProduk: item.namaProduk, varian: item.varian, harga: item.harga, gambar: item.gambar, jumlah: item.jumlah-1));
    } else { _items.remove(cartId); }
    notifyListeners();
  }

  void kurangi(dynamic idOrCartId) {
    String key = idOrCartId.toString();
    // cari yang cocok, bisa idProduk atau cartId
    if (_items.containsKey(key)) {
      removeSingleItem(key);
      return;
    }
    // cari by idProduk
    String? foundKey;
    _items.forEach((k,v){ if(v.idProduk==key) foundKey=k; });
    if (foundKey!=null) removeSingleItem(foundKey!);
  }

  void removeItem(String cartId) { _items.remove(cartId); notifyListeners(); }
  void clear() { _items={}; notifyListeners(); }

  // INI YANG KAMU MAU: EDIT INPUT LANGSUNG KETIK ANGKA
  void setQty(dynamic idOrCartId, int newQty) {
    String key = idOrCartId.toString();
    String? targetKey;

    if (_items.containsKey(key)) {
      targetKey = key;
    } else {
      // cari by idProduk
      _items.forEach((k,v){ if(v.idProduk==key) targetKey=k; });
    }

    if (targetKey==null) return;

    if (newQty <= 0) {
      _items.remove(targetKey);
    } else {
      final old = _items[targetKey]!;
      _items[targetKey] = CartItem(
        idProduk: old.idProduk,
        namaProduk: old.namaProduk,
        varian: old.varian,
        harga: old.harga,
        gambar: old.gambar,
        jumlah: newQty,
      );
    }
    notifyListeners();
  }
}