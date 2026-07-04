class CartItem {
  final String id;
  final String nama;
  final int harga;
  final int hargaNormal;
  final int isPromo;
  final String varian;
  final String gambar; // <-- PAKAI gambar BUKAN foto
  int qty;

  CartItem({
    required this.id,
    required this.nama,
    required this.harga,
    required this.hargaNormal,
    required this.isPromo,
    required this.varian,
    required this.gambar, // <-- gambar
    this.qty = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'harga': harga,
    'harga_normal': hargaNormal,
    'is_promo': isPromo,
    'varian': varian,
    'gambar': gambar, // <-- gambar
    'qty': qty,
  };
}