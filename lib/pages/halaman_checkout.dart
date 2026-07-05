import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cart_provider.dart';
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

    setState(() => _loading = true); // tutup setState

    String pesan = 'Halo ${AppConfig.namaToko}, saya mau order:\n\n';
    cart.items.forEach((key, item) {
      pesan += '- ${item.namaLengkap} x${item.jumlah} = Rp ${item.harga * item.jumlah}\n';
    }); // tutup forEach
    pesan += '\nTotal: Rp ${cart.totalHarga}\n\n';
    pesan += 'Nama: ${_namaController.text}\n';
    pesan += 'Alamat: ${_alamatController.text}\n';
    pesan += 'No HP: ${_nohpController.text}';

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_customer': _namaController.text,
          'alamat': _alamatController.text,
          'no_hp': _nohpController.text,
          'total': cart.totalHarga,
          'items': cart.items.values.map((e) => {
            'id_produk': e.idProduk, // ← ganti dari e.id
            'nama': e.namaLengkap, // ← ganti dari e.nama
            'harga': e.harga,
            'jumlah': e.jumlah, // ← ganti dari e.qty
            'varian': e.varian,
          }).toList(), // tutup toList
        }), // tutup jsonEncode
      ); // tutup post

      if (res.statusCode == 200) {
        cart.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order berhasil dikirim!')),
          ); // tutup SnackBar
          Navigator.pop(context);
        } // tutup if mounted
      } else {
        throw Exception('Gagal kirim order');
      } // tutup else
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        ); // tutup SnackBar
      } // tutup if mounted
    } finally {
      if (mounted) setState(() => _loading = false);
    } // tutup finally
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