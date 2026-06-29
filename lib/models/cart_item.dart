class CartItem {
  final String id;
  final String nama;
  final int harga;
  final String gambar;
  int jumlah;

  CartItem({
    required this.id,
    required this.nama,
    required this.harga,
    required this.gambar,
    this.jumlah = 1,
  });
}