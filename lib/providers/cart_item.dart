class CartItem {
  final String id;
  final String nama;
  final int jumlah;
  final int harga;
  final String gambar;

  CartItem({
    required this.id,
    required this.nama,
    this.jumlah = 1,
    required this.harga,
    required this.gambar,
  });

  // ← Tambahin ini
  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'jumlah': jumlah,
    'harga': harga,
    'gambar': gambar,
  };
}