class CartItem {
  final String idProduk; // id produk asli
  final String namaProduk; 
  final String? varian; // "40kg", "50kg", null kalau nggak ada varian
  final int harga; // harga varian yg dipilih, atau harga umum
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

  // ID unik di cart = idProduk + varian. Biar 40kg & 50kg kehitung beda item
  String get cartId => varian == null? idProduk : '${idProduk}_$varian';

  String get namaLengkap => varian == null? namaProduk : '$namaProduk - $varian';

  Map<String, dynamic> toJson() => {
    'id': idProduk,
    'nama': namaLengkap,
    'harga': harga,
    'gambar': gambar,
    'jumlah': jumlah,
  };
} // tutup CartItem