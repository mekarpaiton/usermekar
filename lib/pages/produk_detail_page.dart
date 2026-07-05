import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

class ProdukDetailPage extends StatefulWidget {
  final Map produk; // data dari API
  const ProdukDetailPage({super.key, required this.produk});

  @override
  State<ProdukDetailPage> createState() => _ProdukDetailPageState(); // tutup createState
} // tutup ProdukDetailPage

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  Map? varianDipilih; // null kalau nggak ada varian

  @override
  void initState() {
    super.initState();
    // Kalau ada varian, pilih yang pertama sebagai default
    final List varianList = widget.produk['varian']?? [];
    if (varianList.isNotEmpty) {
      varianDipilih = varianList[0];
    }
  } // tutup initState

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final List varianList = widget.produk['varian']?? [];
    final bool adaVarian = varianList.isNotEmpty;

    // Harga yg ditampilin = harga varian kalau ada, kalau nggak pake harga umum
    final int hargaTampil = adaVarian? varianDipilih!['harga'] : widget.produk['harga'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produk['nama']),
        backgroundColor: Colors.orange,
      ), // tutup AppBar
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Image.network(
                  widget.produk['gambar'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.image, size: 100),
                ), // tutup Image
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produk['nama'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ), // tutup Text nama
                      const SizedBox(height: 8),
                      Text(
                        'Rp $hargaTampil',
                        style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.w600),
                      ), // tutup Text harga
                      const SizedBox(height: 16),

                      // Pilihan Varian muncul kalau ada
                      if (adaVarian)...[
                        const Text('Pilih Varian:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: varianList.map<Widget>((varian) {
                            final bool dipilih = varianDipilih == varian;
                            return ChoiceChip(
                              label: Text(varian['nama']),
                              selected: dipilih,
                              onSelected: (s) {
                                setState(() => varianDipilih = varian);
                              }, // tutup onSelected
                              selectedColor: Colors.orange,
                              labelStyle: TextStyle(color: dipilih? Colors.white : Colors.black),
                            ); // tutup ChoiceChip
                          }).toList(), // tutup map
                        ), // tutup Wrap
                        const SizedBox(height: 16),
                      ], // tutup if adaVarian

                      const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.produk['deskripsi']?? '-'),
                    ], // tutup children Column
                  ), // tutup Column
                ), // tutup Padding
              ], // tutup children ListView
            ), // tutup ListView
          ), // tutup Expanded

          // Tombol Tambah ke Keranjang
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Tambah ke Keranjang'),
              onPressed: () {
                cart.addItem(
                  widget.produk['id'].toString(),
                  widget.produk['nama'],
                  hargaTampil,
                  widget.produk['gambar'],
                  varian: adaVarian? varianDipilih!['nama'] : null,
                ); // tutup addItem

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.produk['nama']} ditambah'),
                    duration: const Duration(seconds: 1),
                  ), // tutup SnackBar
                ); // tutup showSnackBar
              }, // tutup onPressed
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ), // tutup styleFrom
            ), // tutup ElevatedButton
          ), // tutup Container
        ], // tutup children Column
      ), // tutup Column
    ); // tutup Scaffold
  } // tutup build
} // tutup _ProdukDetailPageState