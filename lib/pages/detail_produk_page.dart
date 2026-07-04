import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

const Color warnaUtama = Color(0xFF7F00FF);

class DetailProdukPage extends StatefulWidget {
  final Map produk;
  const DetailProdukPage({super.key, required this.produk});

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  String? varianDipilih;
  int qty = 1;

  @override
  void initState() {
    super.initState();
    final varianList = widget.produk['varian'] as List;
    if (varianList.isNotEmpty) {
      varianDipilih = varianList[0]['nama']; // default pilih varian pertama
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final isPromo = p['is_promo'] == 1;
    final teksPromo = p['teks_promo']?? '';
    final varianList = p['varian'] as List;
    final hargaUmum = p['harga_umum'] as Map;
    final hargaUmumAsli = p['harga_umum_asli'] as Map;

    // Hitung harga yg aktif
    int hargaFinal = 0;
    int hargaAsli = 0;
    int stokTersedia = p['stok']?? 0;

    if (varianList.isNotEmpty && varianDipilih!= null) {
      final v = varianList.firstWhere((e) => e['nama'] == varianDipilih);
      hargaFinal = v['harga_final'];
      hargaAsli = v['harga_asli'];
      stokTersedia = v['stok']?? 0;
    } else {
      hargaFinal = hargaUmum['umum']?? 0;
      hargaAsli = hargaUmumAsli['umum']?? 0;
    }

    final adaPromo = hargaAsli > hargaFinal;

    return Scaffold(
      appBar: AppBar(
        title: Text(p['nama']),
        backgroundColor: warnaUtama,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Foto gede
                Stack(
                  children: [
                    Image.network(
                      p['foto']?? '',
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
                    ),
                    if (isPromo)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            teksPromo.isNotEmpty? teksPromo : 'PROMO',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nama'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (adaPromo)
                            Text(
                              'Rp $hargaAsli',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          if (adaPromo) const SizedBox(width: 8),
                          Text(
                            'Rp $hargaFinal',
                            style: TextStyle(
                              color: adaPromo? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('/ ${p['satuan']?? ''}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Stok tersedia: $stokTersedia', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 32),

                      // Pilih Varian
                      if (varianList.isNotEmpty)...[
                        const Text('Pilih Varian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: varianList.map((v) {
                            final selected = varianDipilih == v['nama'];
                            final promoVarian = v['is_promo'] == 1;
                            return ChoiceChip(
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(v['nama']),
                                  Text(
                                    'Rp ${v['harga_final']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selected? Colors.white : (promoVarian? Colors.red : Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              selected: selected,
                              onSelected: (val) {
                                setState(() => varianDipilih = v['nama']);
                              },
                              selectedColor: warnaUtama,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Pilih Jumlah
                      const Text('Jumlah:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 1? () => setState(() => qty--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$qty', style: const TextStyle(fontSize: 18)),
                          ),
                          IconButton(
                            onPressed: qty < stokTersedia? () => setState(() => qty++) : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Deskripsi
                      const Text('Deskripsi Produk:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(p['deskripsi']?? 'Tidak ada deskripsi'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tombol Beli
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: stokTersedia == 0? null : () {
                  final v = varianList.isNotEmpty
                    ? varianList.firstWhere((e) => e['nama'] == varianDipilih)
                      : null;

                  Provider.of<CartProvider>(context, listen: false).addItem(
                    p['id'].toString(),
                    p['nama'],
                    hargaFinal,
                    p['foto']?? '',
                    varian: varianDipilih?? 'umum',
                    hargaNormal: hargaAsli,
                    isPromo: adaPromo? 1 : 0,
                  );

                  // Tambah qty kalau > 1
                  if (qty > 1) {
                    final key = '${p['id']}-${varianDipilih?? 'umum'}';
                    for (int i = 1; i < qty; i++) {
                      Provider.of<CartProvider>(context, listen: false).tambahItem(key);
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${p['nama']} ditambahkan ke keranjang'),
                      backgroundColor: warnaUtama,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnaUtama,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  stokTersedia == 0? 'Stok Habis' : 'Tambah ke Keranjang',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}