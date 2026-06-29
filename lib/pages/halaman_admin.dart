import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://abahkhuzai.pythonanywhere.com';
const Color warnaUtama = Color(0xFF7F00FF);

class HalamanAdmin extends StatefulWidget {
  const HalamanAdmin({super.key});
  @override
  State<HalamanAdmin> createState() => _HalamanAdminState();
}

class _HalamanAdminState extends State<HalamanAdmin> {
  List produk = [];
  bool loading = true;

  final idCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  final hargaCtrl = TextEditingController();
  final satuanCtrl = TextEditingController();
  final fotoCtrl = TextEditingController();
  final stokCtrl = TextEditingController();
  final deskripsiCtrl = TextEditingController();
  String kategoriCtrl = 'Semen';

  @override
  void initState() {
    super.initState();
    getProduk();
  }

  Future<void> getProduk() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse('$baseUrl/api/produk'));
    setState(() {
      produk = json.decode(res.body);
      loading = false;
    });
  }

  Future<void> tambahProduk() async {
    if (idCtrl.text.isEmpty || namaCtrl.text.isEmpty || hargaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID, Nama, Harga wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    await http.post(
      Uri.parse('$baseUrl/api/produk'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': idCtrl.text,
        'nama': namaCtrl.text,
        'harga': {satuanCtrl.text: int.parse(hargaCtrl.text)},
        'satuan': satuanCtrl.text,
        'kategori': kategoriCtrl,
        'foto': fotoCtrl.text,
        'stok': int.parse(stokCtrl.text.isEmpty? '0' : stokCtrl.text),
        'deskripsi': deskripsiCtrl.text,
        'varian': {},
      }),
    );

    idCtrl.clear(); namaCtrl.clear(); hargaCtrl.clear(); satuanCtrl.clear();
    fotoCtrl.clear(); stokCtrl.clear(); deskripsiCtrl.clear();
    getProduk();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produk berhasil ditambah!'), backgroundColor: Colors.green),
    );
  }

  Future<void> hapusProduk(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/produk/$id'));
    getProduk();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produk dihapus!'), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin TB. MEKAR'), backgroundColor: Colors.red),
      body: Column(
        children: [
          // FORM TAMBAH PRODUK
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Text('Tambah Produk Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(controller: idCtrl, decoration: InputDecoration(labelText: 'ID Produk: p1, p2', border: OutlineInputBorder())),
                  SizedBox(height: 8),
                  TextField(controller: namaCtrl, decoration: InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder())),
                  SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: hargaCtrl, decoration: InputDecoration(labelText: 'Harga', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    SizedBox(width: 8),
                    Expanded(child: TextField(controller: satuanCtrl, decoration: InputDecoration(labelText: 'Satuan: sak/kg', border: OutlineInputBorder()))),
                  ]),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: kategoriCtrl,
                    decoration: InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                    items: ['Semen','Cat','Pipa','Besi','Keramik','Lainnya'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => kategoriCtrl = v!),
                  ),
                  SizedBox(height: 8),
                  TextField(controller: fotoCtrl, decoration: InputDecoration(labelText: 'Link Foto', border: OutlineInputBorder())),
                  SizedBox(height: 8),
                  TextField(controller: stokCtrl, decoration: InputDecoration(labelText: 'Stok', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  SizedBox(height: 8),
                  TextField(controller: deskripsiCtrl, decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()), maxLines: 2),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: tambahProduk,
                      icon: Icon(Icons.add),
                      label: Text('Tambah Produk'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.all(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LIST PRODUK + HAPUS
          Expanded(
            child: loading
            ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: produk.length,
                  itemBuilder: (ctx, i) {
                    final p = produk[i];
                    final hargaMap = p['harga'] is String? json.decode(p['harga']) : p['harga'];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Image.network(p['foto'], width: 40, height: 40, fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => Icon(Icons.image)),
                        title: Text(p['nama']),
                        subtitle: Text('Rp ${hargaMap.values.first} | Stok: ${p['stok']} | ${p['kategori']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => hapusProduk(p['id']),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}