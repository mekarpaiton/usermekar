class CartItem {
  final String id;
  final String nama;
  final int harga;
  final String varian;
  final String gambar;
  int qty;

  CartItem({
    required this.id,
    required this.nama,
    required this.harga,
    required this.varian,
    required this.gambar,
    this.qty = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'harga': harga,
    'varian': varian,
    'gambar': gambar,
    'qty': qty,
  };
}