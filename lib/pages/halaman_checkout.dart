import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cart_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});
  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState(); // tutup createState
} // tutup HalamanCheckout

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _nohpController = TextEditingController();
  bool _loading = false;

 

Future<void> _kirimOrder() async {
  final cart = Provider.of<CartProvider>(context, listen: false);
  if (cart.items.isEmpty) return;
  
  // Validasi form
  if (_namaController.text.isEmpty || _nohpController.text.isEmpty || _alamatController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lengkapi nama, alamat & no HP dulu'), backgroundColor: Colors.red),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/orders'), // FIX 1: /api/orders bukan /api/order
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // FIX 2: Samain nama field sama backend Flask
        'nama_pembeli': _namaController.text, // bukan nama_customer
        'wa_pembeli': _nohpController.text,   // bukan no_hp
        'alamat': _alamatController.text,
        'total': cart.totalHarga,
        'ongkir': 0, // tambah ini
        'items': cart.items.values.map((e) => {
          'id': e.idProduk,        // bukan id_produk
          'nama': e.namaLengkap,   // udah bener
          'harga': e.harga,
          'qty': e.jumlah,         // bukan jumlah
          'varian': e.varian,
          'gambar': e.gambar,      // tambah ini biar muncul di admin
        }).toList(),
      }),
    ).timeout(Duration(seconds: 20));

    final result = jsonDecode(res.body);

    // FIX 3: Backend lu balikin 201 + success: true
    if (res.statusCode == 201 && result['success'] == true) {
      cart.clear();
      
      // FIX 4: Buka WA Admin otomatis
      String waMsg = 'Halo Kak, saya ${_namaController.text}.\nSaya sudah order di aplikasi.\n\nOrder ID: #${result['order_id']}\nTotal: Rp ${cart.totalHarga}\n\nMohon diproses ya 🙏';
      final waUrl = 'https://wa.me/${AppConfig.waAdmin}?text=${Uri.encodeComponent(waMsg)}';
      if (await canLaunchUrl(Uri.parse(waUrl))) {
        await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order berhasil! Cek WhatsApp'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } else {
      // FIX 5: Ambil pesan error dari backend
      throw Exception(result['error'] ?? 'Server error ${res.statusCode}');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim order: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
} // tutup _kirimOrder

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.orange,
      ), // tutup AppBar
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cart.items.values.map((item) => ListTile(
                        leading: Image.network(
                          item.gambar,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image),
                        ), // tutup Image
                        title: Text(item.namaLengkap), // ← ganti dari item.nama
                        subtitle: Text('Rp ${item.harga}'), // ← hapus hargaNormal
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('x${item.jumlah}'), // ← ganti dari item.qty
                            const SizedBox(width: 8),
                            Text(
                              'Rp ${item.harga * item.jumlah}', // ← ganti dari item.qty
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ), // tutup Text
                          ], // tutup children Row
                        ), // tutup Row
                      )), // tutup map ListTile
                      const Divider(),
                      ListTile(
                        title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          'Rp ${cart.totalHarga}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ), // tutup Text
                      ), // tutup ListTile Total
                    ], // tutup children ListView
                  ), // tutup ListView
                ), // tutup Expanded
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _namaController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      ), // tutup TextField nama
                      const SizedBox(height: 8),
                      TextField(
                        controller: _alamatController,
                        decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                      ), // tutup TextField alamat
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nohpController,
                        decoration: const InputDecoration(labelText: 'No HP / WA'),
                        keyboardType: TextInputType.phone,
                      ), // tutup TextField nohp
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading? null : _kirimOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ), // tutup styleFrom
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Kirim Pesanan'),
                        ), // tutup ElevatedButton
                      ), // tutup SizedBox
                    ], // tutup children Column
                  ), // tutup Column
                ), // tutup Container
              ], // tutup children Column
            ), // tutup Column
    ); // tutup Scaffold
  } // tutup build
} // tutup _HalamanCheckoutState