import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../config.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});
  @override State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _wa = TextEditingController();
  bool _loading = false;
  Map<String, TextEditingController> _ctrls = {};
  String fmt(int a)=>a.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m)=>'${m[1]}.');

  @override
  void dispose(){ _nama.dispose(); _alamat.dispose(); _wa.dispose(); _ctrls.values.forEach((c)=>c.dispose()); super.dispose(); }

  Future<void> kirim() async {
    final cart = context.read<CartProvider>();
    if (_nama.text.trim().isEmpty || _alamat.text.trim().isEmpty || _wa.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data!'))); return;
    }
    setState(()=>_loading=true);
    final items = cart.items.values.map((e)=>{'id':e.idProduk,'nama':e.namaLengkap,'qty':e.jumlah,'harga':e.harga}).toList();
    try {
      await http.post(Uri.parse('${AppConfig.baseUrl}/api/orders'), headers: {'Content-Type':'application/json'}, body: json.encode({'nama_pembeli':_nama.text.trim(),'wa':_wa.text.trim(),'alamat':_alamat.text.trim(),'items':items,'total':cart.totalHarga})).timeout(const Duration(seconds:12));
    } catch(_){}
    final detail = items.map((e)=>"- ${e['nama']} x${e['qty']}").join('\n');
    final pesan = "Halo TB MEKAR mau pesan:\n$detail\nTotal Rp ${fmt(cart.totalHarga)}\nNama: ${_nama.text}\nAlamat: ${_alamat.text}\nWA: ${_wa.text}";
    await launchUrl(Uri.parse(AppConfig.linkWaPesan(pesan)), mode: LaunchMode.externalApplication);
    cart.clear();
    if(mounted) Navigator.pop(context);
    setState(()=>_loading=false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: const Color(0xFF4A148C), foregroundColor: Colors.white, centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
       ...cart.items.entries.map((en){
          final id = en.key; final it = en.value;
          _ctrls[id]??= TextEditingController(text: it.jumlah.toString());
          if(_ctrls[id]!.text!=it.jumlah.toString()) _ctrls[id]!.text = it.jumlah.toString();
          return Card(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
            Image.network(it.gambar, width:50, height:50, fit:BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.image)),
            const SizedBox(width:10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(it.namaProduk, style: const TextStyle(fontWeight:FontWeight.bold, fontSize:13), maxLines:1, overflow:TextOverflow.ellipsis),
              Text('${it.varian} • Rp ${fmt(it.harga)}', style: TextStyle(fontSize:11, color:Colors.grey[600])),
              Text('Rp ${fmt(it.harga*it.jumlah)}', style: const TextStyle(fontWeight:FontWeight.bold, color:Color(0xFF4A148C))),
            ])),
            SizedBox(width:85, child: TextField(
              controller: _ctrls[id],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(labelText:'Jml', isDense:true, border:OutlineInputBorder(borderRadius:BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical:8, horizontal:8)),
              onChanged: (v){ int? n=int.tryParse(v); if(n!=null && n>0) context.read<CartProvider>().setQty(id, n); },
            )),
          ])));
        }),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text('Total', style:TextStyle(fontWeight:FontWeight.bold)), Text('Rp ${fmt(cart.totalHarga)}', style: const TextStyle(fontSize:18, fontWeight:FontWeight.w900, color:Color(0xFF4A148C)))]),
        const SizedBox(height:20),
        TextField(controller:_nama, decoration: const InputDecoration(labelText:'Nama Lengkap', border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:_alamat, maxLines:2, decoration: const InputDecoration(labelText:'Alamat Lengkap', border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:_wa, keyboardType:TextInputType.phone, decoration: const InputDecoration(labelText:'No HP / WA', border:OutlineInputBorder())),
        const SizedBox(height:20),
        SizedBox(height:50, width:double.infinity, child: ElevatedButton(onPressed:_loading?null:kirim, style:ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F00)), child: Text(_loading?'MENGIRIM...':'KIRIM ORDER', style: const TextStyle(color:Colors.white, fontWeight:FontWeight.bold)))),
      ]),
    );
  }
}