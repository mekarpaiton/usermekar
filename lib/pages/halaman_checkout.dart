import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

// Kita pakai library url_launcher untuk memicu fungsi JavaScript di browser secara universal dan aman!
import 'package:url_launcher/url_launcher_string.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});
  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
} // tutup HalamanCheckout

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _nohpController = TextEditingController();
  bool _loading = false;

  Future<void> _kirimOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    if (_namaController.text.isEmpty || _nohpController.text.isEmpty || _alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi nama, alamat & no HP dulu'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_pembeli': _namaController.text,
          'wa_pembeli': _nohpController.text,
          'alamat': _alamatController.text,
          'total': cart.totalHarga,
          'ongkir': 0,
          'items': cart.items.values.map((e) => {
            'id': e.idProduk,
            'nama': e.namaLengkap,
            'harga': e.harga,
            'qty': e.jumlah,
            'varian': e.varian,
            'gambar': e.gambar,
          }).toList(),
        }),
      ).timeout(Duration(seconds: 20));

      final result = jsonDecode(res.body);

      if (res.statusCode == 201 && result['status'] == 'sukses') {
        final totalHarga = cart.totalHarga;
        cart.clear();

        // ========================================================
        // SOLUSI DEWA: Panggil fungsi JS yang kita tanam di index.html
        // Aman 100% di Android APK (diabaikan) dan berjalan lancar di Web Browser
        // ========================================================
        try {
          await launchUrlString("javascript:typeof window.pemicuSuaraSukses === 'function' && window.pemicuSuaraSukses();");
        } catch (_) {}
        // ========================================================

        String waMsg = 'Halo Kak, saya ${_namaController.text}\n'
            'Saya sudah order di aplikasi Toko Bangunan Mekar.\n\n'
            'Order ID: *#${result['order_id']}*\n'
            'Total: *Rp ${totalHarga.toInt()}*\n\n'
            'Mohon diproses ya 🙏';

        final waUrl = AppConfig.linkWaPesan(waMsg);

        try {
          await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
        } catch (e) {
          print('Error buka WA: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order berhasil! Cek WhatsApp'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
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
      ),
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
                        ),
                        title: Text(item.namaLengkap),
                        subtitle: Text('Rp ${item.harga}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('x${item.jumlah}'),
                            const SizedBox(width: 8),
                            Text(
                              'Rp ${item.harga * item.jumlah}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                      const Divider(),
                      ListTile(
                        title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          'Rp ${cart.totalHarga}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _namaController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _alamatController,
                        decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nohpController,
                        decoration: const InputDecoration(labelText: 'No HP / WA'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _kirimOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Kirim Pesanan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  } // tutup build
} // tutup _HalamanCheckoutState
