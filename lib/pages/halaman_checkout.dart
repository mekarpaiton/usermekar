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

    if (res.statusCode == 201 && result['success'] == true) {
      final totalHarga = cart.totalHarga; // simpen dulu sebelum clear
      cart.clear();

      // FIX WA: Langsung launch, jangan pake canLaunchUrl
      String noAdmin = AppConfig.waAdmin.replaceAll(RegExp(r'[^0-9]'), ''); // hapus + - spasi
      if (!noAdmin.startsWith('62')) {
        noAdmin = '62${noAdmin.replaceFirst(RegExp(r'^0'), '')}'; // ubah 08xxx jadi 628xxx
      }
      
      String waMsg = 'Halo Kak, saya ${_namaController.text}%0ASaya sudah order di aplikasi Toko Bangunan Mekar.%0A%0AOrder ID: *#${result['order_id']}*%0ATotal: *Rp $totalHarga*%0A%0AMohon diproses ya 🙏';
      final waUrl = 'https://wa.me/$noAdmin?text=$waMsg';
      
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