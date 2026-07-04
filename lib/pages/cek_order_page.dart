import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config.dart';

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
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/order?hp=$hp')).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode!= 200) throw Exception('Server error ${res.statusCode}');

      final data = json.decode(res.body);
      setState(() {
        orders = data is List? data : [];
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
      return DateFormat('dd/MM/yyyy HH:mm').format(DateFormat('dd/MM/yyyy HH:mm').parse(tgl));
    } catch (_) {
      return tgl;
    }
  }

  String formatRupiah(int angka) {
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
                  onPressed: loading? null : cekOrder,
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
                              final status = o['status']?.toString()?? 'baru';
                              final items = o['items'] is List? o['items'] as List : [];
                              final adaPromo = items.any((i) => i['is_promo'] == 1);

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
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text('Order #${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (adaPromo)...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('PROMO', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      ]
                                    ],
                                  ),
                                  subtitle: Text(formatTanggal(o['created_at'])),
                                  trailing: Text(formatRupiah(o['total']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Pembeli: ${o['nama_pembeli']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text('WA: ${o['wa_pembeli']}'),
                                          const Divider(),
                                         ...items.map<Widget>((item) {
                                            final isPromo = item['is_promo'] == 1;
                                            final hargaNormal = item['harga_normal']?? item['harga'];
                                            return ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              title: Text('${item['nama']} ${item['varian']!= 'umum'? '(${item['varian']})' : ''}'),
                                              subtitle: isPromo? Text(
                                                'Rp ${formatRupiah(hargaNormal)}',
                                                style: const TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ) : null,
                                              trailing: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text('x${item['qty']?? item['jumlah']}'),
                                                  Text(
                                                    'Rp ${formatRupiah(item['harga'])}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isPromo? Colors.red : Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
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