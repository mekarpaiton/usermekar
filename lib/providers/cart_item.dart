class CartItem {
  final String idProduk; 
  final String namaProduk; 
  final String? varian; 
  final int harga; 
  final String gambar;
  int jumlah;

  CartItem({
    required this.idProduk,
    required this.namaProduk,
    this.varian,
    required this.harga,
    required this.gambar,
    this.jumlah = 1,
  });

  // FIX: Jamin pencocokan ID Cart tetap konsisten lintas platform
  String get cartId => (varian == null || varian == 'Umum') ? idProduk : '${idProduk}_$varian';

  String get namaLengkap => (varian == null || varian == 'Umum') ? namaProduk : '$namaProduk - $varian';

  Map<String, dynamic> toJson() => {
    'id': idProduk,
    'nama': namaLengkap,
    'harga': harga,
    'gambar': gambar,
    'jumlah': jumlah,
  };
}
