import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/cart_provider.dart';
import '../config.dart';

// Helper biar aman
int safeInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String formatTotal(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

class ProdukDetailPage extends StatefulWidget {
  final Map produk; // data dari API
  const ProdukDetailPage({super.key, required this.produk});

  @override
  State<ProdukDetailPage> createState() => _ProdukDetailPageState();
} // tutup ProdukDetailPage

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  Map? varianDipilih; // null kalau nggak ada varian

  @override
  void initState() {
    super.initState();
    // Kalau ada varian, pilih yang pertama sebagai default
    final List varianList = widget.produk['varian'] ?? [];
    if (varianList.isNotEmpty) {
      varianDipilih = varianList[0];
    }
  } // tutup initState

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final List varianList = widget.produk['varian'] ?? [];
    final bool adaVarian = varianList.isNotEmpty;

    // FIX: Handle harga_umum bisa Map atau String JSON
    int hargaUmum = 0;
    var hargaUmumRaw = widget.produk['harga_umum'];

    // Kalo masih String, decode dulu
    if (hargaUmumRaw is String) {
      try {
        hargaUmumRaw = jsonDecode(hargaUmumRaw);
      } catch (e) {
        hargaUmumRaw = null;
      }
    }

    if (hargaUmumRaw is Map && hargaUmumRaw['umum'] != null) {
      hargaUmum = safeInt(hargaUmumRaw['umum']);
    } else {
      hargaUmum = safeInt(widget.produk['harga']);
    }

    // Harga yg ditampilin = harga varian kalau ada, kalau nggak pake harga umum
    final int hargaTampil = adaVarian ? safeInt(varianDipilih!['harga']) : hargaUmum;

    // FIX: String buat tampilin harga dengan logic baru
    String hargaDisplay;
    String satuan = widget.produk['satuan']?.toString() ?? 'pcs';
    if (adaVarian && hargaUmum == 0) {
      hargaDisplay = 'klik pilih varian'; // ← UDAH GANTI
    } else if (hargaTampil == 0) {
      hargaDisplay = 'Hubungi Admin';
    } else {
      hargaDisplay = 'Rp ${formatTotal(hargaTampil)} / $satuan';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produk['nama']),
        backgroundColor: Colors.orange,
      ),
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
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produk['nama'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // FIX: Pake hargaDisplay yg udah diolah
                      Text(
                        hargaDisplay,
                        style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),

                      // Pilihan Varian muncul kalau ada
                      if (adaVarian) ...[
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
                              },
                              selectedColor: Colors.orange,
                              labelStyle: TextStyle(color: dipilih ? Colors.white : Colors.black),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.produk['deskripsi'] ?? '-'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tombol Tambah ke Keranjang
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Tambah ke Keranjang'),
              // FIX: Disable tombol kalo harga 0 atau ada varian tapi belum dipilih
              onPressed: (hargaTampil == 0) ? null : () {
                cart.addItem(
                  widget.produk['id'].toString(),
                  widget.produk['nama'],
                  hargaTampil,
                  widget.produk['gambar'],
                  varian: adaVarian ? varianDipilih!['nama'] : null,
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.produk['nama']} ditambah'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  } // tutup build
} // tutup _ProdukDetailPageState