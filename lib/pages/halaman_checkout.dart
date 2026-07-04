import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});
  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final namaCtrl = TextEditingController();
  final hpCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();
  bool loading = false;

  void kirimWA() {
  final cart = Provider.of<CartProvider>(context, listen: false);
  if (cart.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keranjang masih kosong'), backgroundColor: Colors.red),
    );
    return;
  }

  String pesan = 'Halo ${AppConfig.namaToko}, saya mau pesan:\n\n';
  pesan += 'Nama: ${namaCtrl.text}\n';
  pesan += 'HP: ${hpCtrl.text}\n';
  pesan += 'Alamat: ${alamatCtrl.text}\n\n';
  pesan += 'Pesanan:\n';

  for (var item in cart.items.values) {
    pesan += '- ${item.nama} ${item.varian != 'umum' ? '(${item.varian})' : ''} x${item.qty} = Rp ${item.harga * item.qty}\n';
  }
  pesan += '\nTotal: Rp ${cart.totalHarga}';
  pesan += '\n\nMohon diproses ya 🙏';

  kirimWhatsApp(pesan);
}

void kirimWhatsApp(String pesan) async {
  final waUrl = Uri.parse(AppConfig.linkWaApp(pesan)); // <-- PAKE YANG BARU
  
  if (await canLaunchUrl(waUrl)) {
    await launchUrl(waUrl, mode: LaunchMode.externalApplication);
  } else {
    final webUrl = Uri.parse(AppConfig.linkWaPesan(pesan));
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }
}   

  Future<void> simpanOrder() async {
    if (namaCtrl.text.isEmpty || hpCtrl.text.isEmpty || alamatCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data dulu Boss'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => loading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama': namaCtrl.text,
          'wa': hpCtrl.text,
          'alamat': alamatCtrl.text,
          'items': cart.items.values.map((e) => {
            'id': e.id,
            'nama': e.nama,
            'harga': e.harga,
            'harga_normal': e.hargaNormal,
            'is_promo': e.isPromo,
            'varian': e.varian,
            'qty': e.qty,
            'gambar': e.gambar, // <-- gambar
          }).toList(),
          'total': cart.totalHarga,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        cart.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dikirim!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Server error ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim pesanan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF7F00FF),
      ),
      body: cart.items.isEmpty
         ? const Center(child: Text('Keranjang kosong'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hpCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'No. WhatsApp',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: alamatCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ...cart.items.values.map((item) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.gambar, width: 50, height: 50, fit: BoxFit.cover), // <-- gambar
                  ),
                  title: Text('${item.nama} ${item.varian != 'umum' ? '(${item.varian})' : ''}'),
                  subtitle: item.isPromo == 1 ? Text(
                    'Rp ${item.hargaNormal}',
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12),
                  ) : null,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('x${item.qty}'),
                      Text('Rp ${item.harga * item.qty}', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isPromo == 1 ? Colors.red : Colors.black,
                      )),
                    ],
                  ),
                )),
                const Divider(),
                ListTile(
                  title: const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: Text('Rp ${cart.totalHarga}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : kirimWA,
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat WA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : simpanOrder,
                        icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                        label: Text(loading ? 'Mengirim...' : 'Kirim Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F00FF),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}