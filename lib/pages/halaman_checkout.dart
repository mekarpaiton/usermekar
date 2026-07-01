import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cart_provider.dart';
import '../config.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});

  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  bool loading = false;

  Future<void> kirimOrder(CartProvider cart) async {
    if (cart.items.isEmpty) return;

    // 1. Siapkan pesan WA
    String pesan = "Halo TB. MEKAR, saya mau pesan:\n\n";
    cart.items.forEach((key, item) {
      pesan += "${item.nama} (${item.jumlah}x) - Rp ${item.harga * item.jumlah}\n";
    });
    pesan += "\nTotal: Rp ${cart.totalHarga}";

    final encodedPesan = Uri.encodeComponent(pesan);
    final waUrl = Uri.parse('https://wa.me/$waAdmin?text=$encodedPesan');

    setState(() => loading = true);

    try {
      // 2. Kirim ke Panel / API dulu
      final res = await http.post(
        Uri.parse('$baseUrl/api/order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'items': cart.items.values.map((e) => {
            'id': e.id,
            'nama': e.nama,
            'harga': e.harga,
            'jumlah': e.jumlah,
          }).toList(),
          'total': cart.totalHarga,
          'tanggal': DateTime.now().toIso8601String(),
          'via': 'whatsapp',
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Panel error ${res.statusCode}');
      }

      // 3. Sukses masuk Panel, baru buka WA
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        cart.clear();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim ke Panel: $e, tetap buka WA...')),
        );
      }
      // Fallback: tetap buka WA biar order nggak hilang
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        backgroundColor: Colors.orange,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.remove_shopping_cart, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Keranjang masih kosong', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Yuk belanja dulu Boss!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // List Barang di Keranjang
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      final productId = cart.items.keys.toList()[i];
                      return Dismissible(
                        key: ValueKey(productId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 40),
                        ),
                        onDismissed: (direction) {
                          Provider.of<CartProvider>(context, listen: false)
                              .removeItem(productId);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                          child: ListTile(
                            leading: Image.network(
                              item.gambar,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                            title: Text(item.nama),
                            subtitle: Text('Rp ${item.harga} x ${item.jumlah}'),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      Provider.of<CartProvider>(context, listen: false)
                                          .kurangItem(productId);
                                    },
                                  ),
                                  Text(
                                    '${item.jumlah}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: () {
                                      Provider.of<CartProvider>(context, listen: false)
                                          .tambahItem(productId);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total Harga
                Card(
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bayar:', style: TextStyle(fontSize: 20)),
                        Text(
                          'Rp ${cart.totalHarga}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Checkout WA
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                  child: ElevatedButton.icon(
                    icon: loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.chat),
                    label: Text(
                      loading ? 'Mengirim...' : 'Checkout via WhatsApp',
                      style: const TextStyle(fontSize: 18),
                    ),
                    onPressed: cart.items.isEmpty || loading ? null : () => kirimOrder(cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}