import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/cart_provider.dart';
import 'pages/halaman_checkout.dart';
import 'pages/cek_order_page.dart';
import 'pages/produk_detail_page.dart';
import 'pages/web_audio.dart';
import 'config.dart';

const Color warnaUtama = Color(0xFF7F00FF);

void main() {
  if (kIsWeb) registerWebAudio();
  runApp(const TBMekarApp());
}

class TBMekarApp extends StatelessWidget {
  const TBMekarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        title: AppConfig.namaToko,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          primaryColor: warnaUtama,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(backgroundColor: warnaUtama, foregroundColor: Colors.white, elevation: 0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: warnaUtama, foregroundColor: Colors.white),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late AnimationController _rippleController;
  bool _isAtCenter = false;
  bool _isClicked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _rippleController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _alignmentAnimation = Tween<Alignment>(begin: const Alignment(2.2, 3.2), end: Alignment.center).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() { _isAtCenter = true; _isClicked = true; });
          _rippleController.forward();
        }
      }
    });
    _rippleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          String? produkParam = Uri.base.queryParameters['produk'];
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HalamanKatalog(initialProdukId: produkParam)));
        }
      }
    });
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); _rippleController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F00FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false, title: Text(AppConfig.namaToko, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 20, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]))),
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/splashmekar.png', fit: BoxFit.cover)),
        if (_isClicked) AnimatedBuilder(animation: _rippleController, builder: (context, child) => Center(child: CustomPaint(painter: ShockwavePainter(progress: _rippleController.value), size: const Size(200, 200)))),
        AnimatedBuilder(animation: _alignmentAnimation, builder: (context, child) => Align(alignment: _alignmentAnimation.value, child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child), child: _isAtCenter? AnimatedContainer(duration: const Duration(milliseconds: 150), transformAlignment: Alignment.center, transform: Matrix4.identity()..scale(_isClicked? 0.85 : 1.0), child: const Text('📸', key: ValueKey('finger_icon'), style: TextStyle(fontSize: 60))) : const Text('📷', key: ValueKey('tools_icon'), style: TextStyle(fontSize: 85))))),
      ]),
    );
  }
}

class ShockwavePainter extends CustomPainter {
  final double progress; ShockwavePainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final paint1 = Paint()..color = const Color(0xff26a69a).withOpacity(1.0-progress)..style = PaintingStyle.stroke..strokeWidth = 4.0*(1.0-progress);
    canvas.drawCircle(center, progress*130, paint1);
    if (progress>0.2) {
      final progress2 = (progress-0.2)/0.8;
      final paint2 = Paint()..color = Colors.cyanAccent.withOpacity(1.0-progress2)..style = PaintingStyle.stroke..strokeWidth = 2.5*(1.0-progress2);
      canvas.drawCircle(center, progress2*90, paint2);
    }
  }
  @override bool shouldRepaint(covariant ShockwavePainter oldDelegate) => oldDelegate.progress!=progress;
}

class HalamanKatalog extends StatefulWidget {
  final String? initialProdukId; const HalamanKatalog({super.key, this.initialProdukId});
  @override State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  List produk = []; List kategori = ['Semua']; String kategoriDipilih = 'Semua'; bool loading = true; TextEditingController searchCtrl = TextEditingController();
  @override void initState() { super.initState(); getKategori(); getProduk().then((_) { if (widget.initialProdukId!=null) bukaProdukDariLink(widget.initialProdukId!); }); }
  void bukaProdukDariLink(String id) { try { final p = produk.firstWhere((e) => e['id'].toString()==id); WidgetsBinding.instance.addPostFrameCallback((_) { Navigator.push(context, MaterialPageRoute(builder: (_) => ProdukDetailPage(produk: p))); }); } catch (_) {} }
  static void shareProduk(BuildContext context, Map p) { int harga = 0; var raw = p['harga_umum']; if (raw is Map) harga = raw['umum']??0; else if (raw is int) harga = raw; String linkPreview = "${AppConfig.linkPreviewBase}/${p['id']}"; String pesan = "${p['nama']} - Rp $harga - TB. MEKAR Paiton\n\nCek & pesan langsung:\n$linkPreview"; Share.share(pesan); }
  Future<void> getKategori() async { try { final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/kategori')); final data = json.decode(res.body) as List; setState(() { kategori = ['Semua',...data.map((e) => e['nama'].toString())]; }); } catch (e) { print('Error kategori: $e'); } }
  Future<void> getProduk({String? search, String? kat}) async { setState(() => loading=true); try { String url='${AppConfig.baseUrl}/api/produk?'; if (search!=null&&search.isNotEmpty) url+='q=$search&'; if (kat!=null&&kat!='Semua') url+='kategori=$kat'; final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15)); setState(() { produk = json.decode(res.body); loading=false; }); } catch (e) { setState(() => loading=false); } }
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(AppConfig.namaToko), backgroundColor: warnaUtama, actions: [IconButton(icon: Icon(Icons.receipt_long), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CekOrderPage())))]),
      body: Column(children: [
        Padding(padding: EdgeInsets.all(12), child: TextField(controller: searchCtrl, decoration: InputDecoration(hintText: 'Cari semen, cat, besi...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => getProduk(search: v, kat: kategoriDipilih))),
        SizedBox(height: 50, child: ListView.builder(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 8), itemCount: kategori.length, itemBuilder: (ctx,i) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(kategori[i]), selected: kategoriDipilih==kategori[i], onSelected: (s){ setState(()=>kategoriDipilih=kategori[i]); getProduk(search: searchCtrl.text, kat: kategori[i]); }, selectedColor: warnaUtama, labelStyle: TextStyle(color: kategoriDipilih==kategori[i]?Colors.white:Colors.black))))),
        Expanded(child: loading?Center(child: CircularProgressIndicator()):produk.isEmpty?Center(child: Text('Produk tidak ditemukan')):RefreshIndicator(onRefresh: ()=>getProduk(kat: kategoriDipilih), child: GridView.builder(padding: EdgeInsets.all(12), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: produk.length, itemBuilder: (ctx,i){
          final p=produk[i]; int hargaUmum=0; var raw=p['harga_umum']; if (raw is Map) hargaUmum=raw['umum']??0; else if (raw is int) hargaUmum=raw;
          String formatRibuan(int angka)=>angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m)=>'${m[1]}.'); String hargaDisplay=hargaUmum==0?'Pilih varian boss':'Rp ${formatRibuan(hargaUmum)} / ${p['satuan']??'sak'}';
          return GestureDetector(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>ProdukDetailPage(produk: p))), child: Card(elevation: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Stack(children: [ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(p['foto']??'', width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.grey[300], child: Icon(Icons.image, size: 50)))), Positioned(top: 4, right: 4, child: InkWell(onTap: ()=>shareProduk(context,p), child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.share, size: 16, color: warnaUtama))))])),
            Padding(padding: EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['nama'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), SizedBox(height: 4), Text(hargaDisplay, style: TextStyle(color: hargaUmum==0?Colors.orange:warnaUtama, fontWeight: FontWeight.bold, fontSize: hargaUmum==0?13:15)), SizedBox(height: 4), Text('Stok: ${p['stok']}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))])),
          ])));
        }))),
      ]),
      floatingActionButton: Consumer<CartProvider>(builder: (ctx,cart,child)=>FloatingActionButton.extended(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>HalamanCheckout())), backgroundColor: warnaUtama, icon: badges.Badge(badgeContent: Text(cart.totalItem.toString(), style: TextStyle(color: Colors.white)), showBadge: cart.totalItem>0, child: Icon(Icons.shopping_cart)), label: Text('Rp ${cart.totalHarga}'))),
    );
  }
}