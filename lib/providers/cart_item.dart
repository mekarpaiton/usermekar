class CartItem {
  final String id;
  final String nama;
  final int harga; // harga final yg dibayar user
  final int hargaNormal; // harga sebelum promo, buat dicoret
  final int isPromo; // 0 atau 1
  final String varian;
  final String gambar;
  int jumlah;

  CartItem({
    required this.id,
    required this.nama,
    required this.harga,
    required this.hargaNormal,
    required this.isPromo,
    required this.varian,
    required this.gambar,
    this.jumlah = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'harga': harga,
    'harga_normal': hargaNormal,
    'is_promo': isPromo,
    'varian': varian,
    'gambar': gambar,
    'qty': jumlah,
  };
}