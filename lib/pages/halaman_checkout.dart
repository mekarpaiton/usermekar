import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class HalamanCheckout extends StatelessWidget {
  const HalamanCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang Belanja'),
        backgroundColor: Colors.orange,
      ),
      body: cart.items.isEmpty
         ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white, size: 40),
                        ),
                        onDismissed: (direction) {
                          Provider.of<CartProvider>(context, listen: false)
                             .removeItem(productId);
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                          child: ListTile(
                            leading: Image.network(
                              item.gambar,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(item.nama),
                            subtitle: Text('Rp ${item.harga} x ${item.jumlah}'),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Tombol Kurang
                                  IconButton(
                                    icon: Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      Provider.of<CartProvider>(context, listen: false)
                                         .kurangItem(productId);
                                    },
                                  ),
                                  // Angka Qty
                                  Text(
                                    '${item.jumlah}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  // Tombol Tambah
                                  IconButton(
                                    icon: Icon(Icons.add_circle, color: Colors.green),
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
                    }, // ← Kurung tutup ListView.builder yg kurang
                  ),
                ), // ← Kurung tutup Expanded yg kurang

                // Total Harga
                Card(
                  margin: EdgeInsets.all(15),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bayar:', style: TextStyle(fontSize: 20)),
                        Text(
                          'Rp ${cart.totalHarga}',
                          style: TextStyle(
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
                  margin: EdgeInsets.fromLTRB(15, 0, 15, 15),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.chat),
                    label: Text('Checkout via WhatsApp', style: TextStyle(fontSize: 18)),
                    onPressed: cart.items.isEmpty? null : () async {
                      String pesan = "Halo TB. MEKAR, saya mau pesan:\n\n";
                      cart.items.forEach((key, item) {
                        pesan += "${item.nama} (${item.jumlah}x) - Rp ${item.harga * item.jumlah}\n";
                      });
                      pesan += "\nTotal: Rp ${cart.totalHarga}";

                      final encodedPesan = Uri.encodeComponent(pesan);
                      final waUrl = Uri.parse('https://wa.me/$waAdmin?text=$encodedPesan');

                      if (await canLaunchUrl(waUrl)) {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tidak bisa buka WhatsApp')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}