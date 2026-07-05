import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

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
      varianDipilih = varianList[0]['nama'];
    }
  }

  int getHarga() {
    final varianList = widget.produk['varian'] as List;
    if (varianList.isNotEmpty && varianDipilih!= null) {
      final v = varianList.firstWhere((e) => e['nama'] == varianDipilih);
      return v['harga'];
    }
    return widget.produk['harga_umum']['umum']?? 0;
  }

  int getStok() {
    final varianList = widget.produk['varian'] as List;
    if (varianList.isNotEmpty && varianDipilih!= null) {
      final v = varianList.firstWhere((e) => e['nama'] == varianDipilih);
      return v['stok']?? 0;
    }
    return widget.produk['stok']?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final varianList = p['varian'] as List;
    final harga = getHarga();
    final stok = getStok();

    return Scaffold(
      appBar: AppBar(title: Text(p['nama']), backgroundColor: Color(0xFF7F00FF)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Image.network(
                  p['foto']?? '',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 300, color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 80),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nama'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Rp $harga', style: TextStyle(color: Color(0xFF7F00FF), fontWeight: FontWeight.bold, fontSize: 24)),
                          Text(' / ${p['satuan']?? ''}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Text('Stok: $stok', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 32),
                      if (varianList.isNotEmpty)...[
                        const Text('Pilih Varian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: varianList.map((v) {
                            final selected = varianDipilih == v['nama'];
                            return ChoiceChip(
                              label: Text('${v['nama']} - Rp ${v['harga']}'),
                              selected: selected,
                              onSelected: (val) => setState(() => varianDipilih = v['nama']),
                              selectedColor: Color(0xFF7F00FF),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Jumlah:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(onPressed: qty > 1? () => setState(() => qty--) : null, icon: const Icon(Icons.remove_circle_outline)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                            child: Text('$qty', style: const TextStyle(fontSize: 18)),
                          ),
                          IconButton(onPressed: qty < stok? () => setState(() => qty++) : null, icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text('Deskripsi:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(p['deskripsi']?? 'Tidak ada deskripsi'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: stok == 0? null : () {
                  Provider.of<CartProvider>(context, listen: false).addItem(
                    p['id'].toString(),
                    p['nama'],
                    harga,
                    p['foto']?? '',
                    varian: varianDipilih?? 'umum',
                  );
                  if (qty > 1) {
                    final key = '${p['id']}-${varianDipilih?? 'umum'}';
                    for (int i = 1; i < qty; i++) {
                      Provider.of<CartProvider>(context, listen: false).tambahItem(key);
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${p['nama']} ditambahkan'), backgroundColor: Color(0xFF7F00FF)),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF7F00FF), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(stok == 0? 'Stok Habis' : 'Tambah ke Keranjang', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}