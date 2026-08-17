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

  String fmt(int a) => a.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Future<void> kirim() async {
    final cart = context.read<CartProvider>();
    if (_nama.text.isEmpty || _alamat.text.isEmpty || _wa.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data!')));
      return;
    }
    setState(() => _loading = true);
    final items = cart.items.values.map((e) => {'id': e.produk['id'], 'nama': e.produk['nama'], 'qty': e.qty, 'harga': e.harga}).toList();
    final body = {'nama_pembeli': _nama.text, 'wa': _wa.text, 'alamat': _alamat.text, 'items': items, 'total': cart.totalHarga};
    try {
      await http.post(Uri.parse('${AppConfig.baseUrl}/api/orders'),
          headers: {'Content-Type':'application/json'}, body: json.encode(body)).timeout(const Duration(seconds: 10));
    } catch (_) {}
    // Langsung WA walau server error
    final detail = items.map((e) => "- ${e['nama']} x${e['qty']}").join('\n');
    final pesan = "Halo TB MEKAR mau pesan:\n$detail\nTotal Rp ${fmt(cart.totalHarga)}\nNama: ${_nama.text}\nAlamat: ${_alamat.text}\nWA: ${_wa.text}";
    await launchUrl(Uri.parse(AppConfig.linkWaPesan(pesan)), mode: LaunchMode.externalApplication);
    cart.clear();
    if (mounted) Navigator.pop(context);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: const Color(0xFF4A148C), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...cart.items.values.map((e) => Card(
            child: ListTile(
              leading: Image.network(e.produk['foto']??'', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,_,__) => const Icon(Icons.image)),
              title: Text(e.produk['nama'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('Rp ${fmt(e.harga)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => context.read<CartProvider>().kurangi(e.produk['id'])),
                  Text('x${e.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => context.read<CartProvider>().tambah(e.produk)),
                  const SizedBox(width: 8),
                  Text('Rp ${fmt(e.harga * e.qty)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                ],
              ),
            ),
          )),
          const Divider(),
          Text('Total Rp ${fmt(cart.totalHarga)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _alamat, decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 10),
          TextField(controller: _wa, decoration: const InputDecoration(labelText: 'No HP / WA', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loading?null:kirim, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(_loading?'MENGIRIM...':'KIRIM & WA ADMIN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}