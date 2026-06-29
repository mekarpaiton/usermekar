class CartItem {
  final String id;
  final String nama;
  final int jumlah; // ← Pake 'jumlah' bukan 'qty'
  final int harga;
  final String gambar; // ← Pake 'gambar' bukan 'imageUrl'

  CartItem({
    required this.id,
    required this.nama,
    this.jumlah = 1, // Default 1
    required this.harga,
    required this.gambar,
  });
}