import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'halaman_checkout.dart';

class HalamanKatalog extends StatelessWidget {
  const HalamanKatalog({super.key});

  // Data produk dummy. Nanti ganti dari Firebase
  final List<Map<String, dynamic>> produk = const [
    {
      'id': 'p1',
      'nama': 'Semen Gresik 50kg',
      'harga': 65000,
      'gambar': 'https://via.placeholder.com/150' // Ganti link gambar asli
    },
    {
      'id': 'p2',
      'nama': 'Cat Tembok Avian 5kg',
      'harga': 120000,
      'gambar': 'https://via.placeholder.com/150'
    },
    {
      'id': 'p3',
      'nama': 'Pipa PVC 3 Inch',
      'harga': 45000,
      'gambar': 'https://via.placeholder.com/150'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TB. MEKAR'),
        backgroundColor: Colors.orange,
        actions: [
          // Icon Keranjang + Badge
          Consumer<CartProvider>(
            builder: (ctx, cart, child) => Badge(
              label: Text(cart.totalItem.toString()),
              isLabelVisible: cart.totalItem > 0,
              child: IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => HalamanCheckout()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: produk.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (ctx, i) => Card(
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  produk[i]['gambar'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      produk[i]['nama'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    SizedBox(height: 4),
                    Text('Rp ${produk[i]['harga']}', style: TextStyle(color: Colors.orange)),
                    SizedBox(height: 8),
                    // Tombol Tambah ke Keranjang
                    Consumer<CartProvider>(
                      builder: (ctx, cart, child) => ElevatedButton.icon(
                        icon: Icon(Icons.add_shopping_cart, size: 18),
                        label: Text('Tambah'),
                        onPressed: () {
                          cart.addItem(
                            produk[i]['id'],
                            produk[i]['nama'],
                            produk[i]['harga'],
                            produk[i]['gambar'],
                          );
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${produk[i]['nama']} ditambah ke keranjang'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}