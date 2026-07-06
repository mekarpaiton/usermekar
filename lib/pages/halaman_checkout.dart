import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:js_interop'; // FIX: Menggunakan interop modern agar lolos compile Wasm di GitHub Actions
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

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

      // FIX BARU: Sesuaikan dengan response server Flask yang mengirimkan 'status': 'sukses'
      if (res.statusCode == 201 && result['status'] == 'sukses') {
        final totalHarga = cart.totalHarga;
        cart.clear();

        // ========================================================
        // GABUNGAN NOTIFIKASI: ASISTEN GOOGLE + SUARA UNTUK PELANGGAN
        // ========================================================
        try {
          final jsCode = '''
            (function() {
              const ctx = new (window.AudioContext || window.webkitAudioContext)();
              
              // 1. Efek Nada Mantap "Ting-Ting!"
              const osc1 = ctx.createOscillator(); const gain1 = ctx.createGain();
              osc1.type = 'sine'; osc1.frequency.setValueAtTime(523.25, ctx.currentTime);
              gain1.gain.setValueAtTime(0.15, ctx.currentTime);
              gain1.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
              osc1.connect(gain1); gain1.connect(ctx.destination);
              osc1.start(); osc1.stop(ctx.currentTime + 0.15);
              
              setTimeout(() => {
                const osc2 = ctx.createOscillator(); const gain2 = ctx.createGain();
                osc2.type = 'sine'; osc2.frequency.setValueAtTime(659.25, ctx.currentTime);
                gain2.gain.setValueAtTime(0.2, ctx.currentTime);
                gain2.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
                osc2.connect(gain2); gain2.connect(ctx.destination);
                osc2.start(); osc2.stop(ctx.currentTime + 0.3);
              }, 100);

              // 2. Asisten Google berbicara ke Pelanggan
              setTimeout(() => {
                if ('speechSynthesis' in window) {
                  window.speechSynthesis.cancel();
                  let ucapan = new SpeechSynthesisUtterance("Orderan sukses bos! Silakan klik kirim di WhatsApp ya.");
                  ucapan.lang = "id-ID";
                  ucapan.rate = 1.0;
                  window.speechSynthesis.speak(ucapan);
                }
              }, 500);
            })();
          ''';

          // Eksekusi kode lewat globalContext eval bawaan dart:js_interop (Aman untuk build Web/Wasm)
          (globalContext['eval'] as JSFunction).call(null, jsCode.toJS);
          
        } catch (audioError) {
          print('Gagal memutar audio pelanggan: \$audioError');
        }
        // ========================================================

        // Teks WA menggunakan '\n' agar rapi saat terbaca di WhatsApp chat
        String waMsg = 'Halo Kak, saya ${_namaController.text}\n'
            'Saya sudah order di aplikasi Toko Bangunan Mekar.\n\n'
            'Order ID: *#${result['order_id']}*\n'
            'Total: *Rp ${totalHarga.toInt()}*\n\n'
            'Mohon diproses ya 🙏';

        // FIX BARU: Langsung panggil fungsi encoder bawaan dari AppConfig kamu biar aman
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
