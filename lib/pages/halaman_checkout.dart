import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});
  @override State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _wa = TextEditingController();
  bool _loading = false;
  Map<String, TextEditingController> _qtyCtrls = {};

  String fmt(int a) => a.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  TextEditingController _getCtrl(String id, int qty) {
    if (!_qtyCtrls.containsKey(id)) {
      _qtyCtrls[id] = TextEditingController(text: qty.toString());
    }
    return _qtyCtrls[id]!;
  }

  Future<void> kirim() async {
    final cart = context.read<CartProvider>();
    if (_nama.text.trim().isEmpty || _alamat.text.trim().isEmpty || _wa.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi Nama, Alamat, WA!')));
      return;
    }
    setState(() => _loading = true);
    final items = cart.items.values.map((e) => {'id': e.produk['id'], 'nama': e.produk['nama'], 'qty': e.qty, 'harga': e.harga}).toList();
    final body = {'nama_pembeli': _nama.text.trim(), 'wa': _wa.text.trim(), 'alamat': _alamat.text.trim(), 'items': items, 'total': cart.totalHarga};

    try {
      final res = await http.post(Uri.parse('${AppConfig.baseUrl}/api/orders'),
          headers: {'Content-Type':'application/json'}, body: json.encode(body)).timeout(const Duration(seconds: 12));
      print('ORDER RES ${res.statusCode} ${res.body}'); // biar ketauan kalau masih 200 error
    } catch (e) {
      print('ORDER ERR $e');
    }

    final detail = items.map((e) => "- ${e['nama']} x${e['qty']}").join('\n');
    final pesan = "Halo TB MEKAR mau pesan:\n$detail\nTotal Rp ${fmt(cart.totalHarga)}\nNama: ${_nama.text}\nAlamat: ${_alamat.text}\nWA: ${_wa.text}";
    await launchUrl(Uri.parse(AppConfig.linkWaPesan(pesan)), mode: LaunchMode.externalApplication);
    cart.clear();
    if (mounted) Navigator.pop(context);
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nama.dispose(); _alamat.dispose(); _wa.dispose();
    _qtyCtrls.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: const Color(0xFF4A148C), foregroundColor: Colors.white, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
         ...cart.items.values.map((e) {
            final ctrl = _getCtrl(e.produk['id'].toString(), e.qty);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Image.network(e.produk['foto']??'', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.image)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.produk['nama'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Rp ${fmt(e.harga)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text('Rp ${fmt(e.harga * e.qty)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                    ])),
                    const SizedBox(width: 10),
                    // INI INPUT LANGSUNG EDIT BUKAN +/-
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(labelText: 'Jml', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                        onChanged: (v) {
                          int? n = int.tryParse(v);
                          if (n!= null && n > 0) {
                            context.read<CartProvider>().setQty(e.produk['id'], n);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('Rp ${fmt(cart.totalHarga)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4A148C)))]),
          const SizedBox(height: 20),
          TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _alamat, decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 10),
          TextField(controller: _wa, decoration: const InputDecoration(labelText: 'No HP / WA', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading?null:kirim, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F00)), child: Text(_loading?'MENGIRIM...':'KIRIM ORDER', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}