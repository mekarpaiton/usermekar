import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

const Color warnaUtama = Color(0xFF7F00FF);

class CekOrderPage extends StatefulWidget {
  const CekOrderPage({super.key});

  @override
  State<CekOrderPage> createState() => _CekOrderPageState();
}

class _CekOrderPageState extends State<CekOrderPage> {
  final hpController = TextEditingController();
  bool loading = false;
  List orders = [];
  String? error;

  Future<void> cekOrder() async {
    final hp = hpController.text.trim();
    if (hp.isEmpty) return;

    setState(() { loading = true; error = null; orders = []; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/order?hp=$hp'))
         .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        setState(() { orders = json.decode(res.body); });
      } else {
        setState(() { error = 'Gagal ambil data'; });
      }
    } catch (e) {
      setState(() { error = 'Cek koneksi internet'; });
    }
    setState(() { loading = false; });
  }

  Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'selesai': return Colors.green;
      case 'diproses': return Colors.orange;
      case 'batal': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: hpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'No. WA',
                hintText: '6281234...',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading? null : cekOrder,
                child: Text(loading? 'Mencari...' : 'Cek Status'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: error!= null
                 ? Center(child: Text(error!))
                  : orders.isEmpty
                     ? const Center(child: Text('Masukkan No. WA untuk cek pesanan'))
                      : ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (c, i) {
                            final o = orders[i];
                            return Card(
                              child: ListTile(
                                title: Text(o['id']?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${o['waktu']}\nTotal: Rp ${o['total']}'),
                                trailing: Chip(
                                  label: Text(
                                    (o['status']?? 'baru').toString().toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                  backgroundColor: statusColor(o['status']?? 'baru'),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}