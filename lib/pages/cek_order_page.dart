import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // ← IMPORT CONFIG

class CekOrderPage extends StatefulWidget {
  const CekOrderPage({super.key});
  @override
  State<CekOrderPage> createState() => _CekOrderPageState();
}

class _CekOrderPageState extends State<CekOrderPage> {
  final hpCtrl = TextEditingController();
  List orders = [];
  bool loading = false;
  String errorMsg = '';

  Future<void> cekOrder() async {
    if (hpCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor HP dulu'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      loading = true;
      errorMsg = '';
      orders = [];
    });

    try {
      final hp = hpCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/order?hp=$hp')).timeout(const Duration(seconds: 15)); // ← PAKE CONFIG
      
      if (!mounted) return;

      if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
      
      final data = json.decode(res.body);
      setState(() {
        orders = data is List ? data : [];
        loading = false;
        if (orders.isEmpty) errorMsg = 'Tidak ada pesanan dengan nomor ini';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMsg = 'Gagal cek pesanan: $e';
      });
    }
  }

  Color warnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'baru': return Colors.red;
      case 'diproses': return Colors.orange;
      case 'selesai': return Colors.green;
      case 'batal': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String formatTanggal(String? tgl) {
    if (tgl == null) return '-';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tgl));
    } catch (_) {
      return tgl;
    }
  }

  String formatTotal(dynamic total) {
    int angka = 0;
    if (total is num) {
      angka = total.toInt();
    } else {
      angka = int.tryParse(total.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Pesanan'),
        backgroundColor: const Color(0xFF7F00FF),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hpCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: loading ? null : cekOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F00FF),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CEK'),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMsg.isNotEmpty
                    ? Center(child: Text(errorMsg, style: const TextStyle(color: Colors.red)))
                    : orders.isEmpty
                        ? const Center(child: Text('Masukkan nomor HP untuk cek pesanan'))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (ctx, i) {
                              final o = orders[i];
                              final status = o['status']?.toString() ?? 'Baru';
                              final items = o['items'] is List ? o['items'] as List : [];
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ExpansionTile(
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: warnaStatus(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text('Order #${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(formatTanggal(o['created_at'])),
                                  trailing: Text(formatTotal(o['total']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  children: [
                                    ...items.map<Widget>((item) => ListTile(
                                      dense: true,
                                      title: Text(item['nama']?.toString() ?? 'Item'),
                                      trailing: Text('x${item['qty'] ?? 1}'),
                                    )),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}