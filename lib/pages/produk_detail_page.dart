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
}

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  Map? varianDipilih; // null kalau nggak ada varian

  @override
  void initState() {
    super.initState();
    final List varianList = widget.produk['varian'] ?? [];
    if (varianList.isNotEmpty) {
      varianDipilih = varianList[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final List varianList = widget.produk['varian'] ?? [];
    final bool adaVarian = varianList.isNotEmpty;

    // Amankan link foto dari katalog ('foto')
    String linkFoto = widget.produk['foto'] ?? widget.produk['gambar'] ?? '';

    // ========================================================
    // SINKRONISASI LOGIKA HARGA DENGAN KATALOG UTAMA
    // ========================================================
    int hargaUmum = 0;
    var hargaUmumRaw = widget.produk['harga_umum'];

    if (hargaUmumRaw is String) {
      try {
        hargaUmumRaw = jsonDecode(hargaUmumRaw);
      } catch (_) {}
    }

    if (hargaUmumRaw is Map) {
      hargaUmum = safeInt(hargaUmumRaw['umum']);
    } else if (hargaUmumRaw != null && hargaUmumRaw is! Map) {
      // JIKA LANGSUNG ANGKA MURNI (Sama seperti logika di Katalog)
      hargaUmum = safeInt(hargaUmumRaw);
    }

    // Jika harga_umum masih 0, ambil fallback dari key 'harga'
    if (hargaUmum == 0) {
      hargaUmum = safeInt(widget.produk['harga']);
    }

    // Tentukan harga yang akan ditampilkan dan dikirim ke keranjang
    int hargaTampil = 0;
    if (adaVarian) {
      hargaTampil = varianDipilih != null ? safeInt(varianDipilih!['harga']) : 0;
    } else {
      hargaTampil = hargaUmum;
    }

    // String buat tampilin harga ke pembeli
    String hargaDisplay;
    String satuan = widget.produk['satuan']?.toString() ?? 'pcs';
    if (adaVarian && varianDipilih == null) {
      hargaDisplay = 'klik pilih varian'; 
    } else if (hargaTampil == 0) {
      hargaDisplay = 'Hubungi Admin';
    } else {
      hargaDisplay = 'Rp ${formatTotal(hargaTampil)} / $satuan';
    }

    // ========================================================
    // FIX DEWA: PAKSA TOMBOL ORANJE JIKA PRODUK KATALOG UMUM
    // ========================================================
    bool tombolAktif = false;
    if (adaVarian) {
      // Jika bervarian, tombol aktif kalau sudah diklik variannya
      tombolAktif = (varianDipilih != null);
    } else {
      // JIKA PRODUK UMUM, UTAMAKAN SELALU AKTIF (TRUE)!
      tombolAktif = true; 
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
                  linkFoto,
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
                      Text(
                        hargaDisplay,
                        style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),

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
                                setState(() => varianDipilih = s ? varian : null);
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
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text('Tambah ke Keranjang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              // Logika OnPressed dikunci berdasarkan status tombolAktif
              onPressed: !tombolAktif ? null : () {
                // Pengaman ganda: jika karena satu hal hargaTampil terbaca 0, 
                // kita ambil paksa dari nominal backup hargaUmum atau widget.produk['harga']
                int hargaFinal = (hargaTampil == 0) ? (hargaUmum > 0 ? hargaUmum : safeInt(widget.produk['harga'])) : hargaTampil;

                cart.addItem(
                  widget.produk['id'].toString(),
                  widget.produk['nama'],
                  hargaFinal,
                  linkFoto,
                  varian: adaVarian ? varianDipilih!['nama'] : "Umum",
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.produk['nama']} ditambah ke keranjang'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                // Mengikuti perintah boss: PAKSA ORANGE jika tombolAktif bernilai true
                backgroundColor: tombolAktif ? Colors.orange : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
