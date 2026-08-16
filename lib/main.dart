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

const Color warnaUtama = Color(0xFF4A148C);
const Color warnaEmas = Color(0xFFD4AF37);
const Color warnaCream = Color(0xFFFFF8E1);

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
          scaffoldBackgroundColor: warnaCream,
          primaryColor: warnaUtama,
          appBarTheme: const AppBarTheme(backgroundColor: warnaUtama, foregroundColor: Colors.white, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(fontFamily: 'Serif', fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          chipTheme: ChipThemeData(selectedColor: warnaUtama, backgroundColor: Colors.white, secondarySelectedColor: warnaUtama, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: warnaUtama.withOpacity(0.3)))),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// Splash Tetap - TIDAK DIHAPUS
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller; late Animation<Alignment> _alignmentAnimation; late AnimationController _rippleController; bool _isAtCenter = false; bool _isClicked = false;
  @override void initState() { super.initState(); _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this); _rippleController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this); _alignmentAnimation = Tween<Alignment>(begin: const Alignment(2.2, 3.2), end: Alignment.center).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn)); _controller.addStatusListener((status) { if (status == AnimationStatus.completed) { if (mounted) { setState(() { _isAtCenter = true; _isClicked = true; }); _rippleController.forward(); } } }); _rippleController.addStatusListener((status) { if (status == AnimationStatus.completed) { if (mounted) { String? produkParam = Uri.base.queryParameters['produk']; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HalamanKatalog(initialProdukId: produkParam))); } } }); _controller.forward(); }
  @override void dispose() { _controller.dispose(); _rippleController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: warnaUtama, extendBodyBehindAppBar: true, appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false, title: Text(AppConfig.namaToko, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 20, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]))), body: Stack(children: [Positioned.fill(child: Image.asset('assets/images/splashmekar.png', fit: BoxFit.cover)), if (_isClicked) AnimatedBuilder(animation: _rippleController, builder: (context, child) => Center(child: CustomPaint(painter: ShockwavePainter(progress: _rippleController.value), size: const Size(200, 200)))), AnimatedBuilder(animation: _alignmentAnimation, builder: (context, child) => Align(alignment: _alignmentAnimation.value, child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child), child: _isAtCenter? AnimatedContainer(duration: const Duration(milliseconds: 150), transformAlignment: Alignment.center, transform: Matrix4.identity()..scale(_isClicked? 0.85 : 1.0), child: const Text('📸', key: ValueKey('finger_icon'), style: TextStyle(fontSize: 60))) : const Text('📷', key: ValueKey('tools_icon'), style: TextStyle(fontSize: 85))))),]),);
  }
}
class ShockwavePainter extends CustomPainter {
  final double progress;
  ShockwavePainter({required this.progress});
  @override void paint(Canvas canvas, Size size) {
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

// ================= HALAMAN KATALOG TANPA PROMO + APPBAR ANIMASI =================
class HalamanKatalog extends StatefulWidget {
  final String? initialProdukId; const HalamanKatalog({super.key, this.initialProdukId});
  @override State<HalamanKatalog> createState() => _HalamanKatalogState();
}
class _HalamanKatalogState extends State<HalamanKatalog> {
  List produk = []; List kategori = ['Semua']; String kategoriDipilih = 'Semua'; bool loading = true; TextEditingController searchCtrl = TextEditingController();

  int parseHarga(dynamic raw) {
    if (raw == null) return 0;
    try {
      if (raw is int) return raw;
      if (raw is Map) return int.tryParse('${raw['umum']??raw['harga']??0}')??0;
      if (raw is String && raw.isNotEmpty) {
        try { var j=json.decode(raw); if(j is Map) return int.tryParse('${j['umum']??j['harga']??0}')??0; return int.tryParse(raw)??0; } catch(_){ return int.tryParse(raw)??0; }
      }
    } catch(_){}
    return 0;
  }

  @override void initState() { super.initState(); getKategori(); getProduk().then((_) { if (widget.initialProdukId!=null) bukaProdukDariLink(widget.initialProdukId!); }); }
  void bukaProdukDariLink(String id) { try { final p = produk.firstWhere((e) => e['id'].toString()==id); WidgetsBinding.instance.addPostFrameCallback((_) { Navigator.push(context, MaterialPageRoute(builder: (_) => ProdukDetailPage(produk: p))); }); } catch (_) {} }
  static void shareProduk(BuildContext context, Map p) {
    int harga=0; try{ var raw=p['harga_umum']??p['harga']; if(raw is Map) harga=raw['umum']??0; else if(raw is String){ try{ var j=json.decode(raw); if(j is Map) harga=j['umum']??0; }catch(_){} } else if(raw is int) harga=raw; }catch(_){}
    String linkPreview = "${AppConfig.baseUrl}/p/${p['id']}";
    String pesan = "✨ ${p['nama']} - Rp $harga - ${AppConfig.namaToko} Paiton\nCek langsung:\n$linkPreview\n\nREADY STOK BOS! 🔥";
    Share.share(pesan);
  }
  Future<void> getKategori() async { try { final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/kategori')); final data = json.decode(res.body) as List; setState(() { kategori = ['Semua',...data.map((e) => e['nama'].toString())]; }); } catch (e) {} }
  Future<void> getProduk({String? search, String? kat}) async {
    setState(() => loading=true);
    try {
      String url='${AppConfig.baseUrl}/api/produk'; List<String> qp=[];
      if(search!=null&&search.isNotEmpty) qp.add('q=${Uri.encodeComponent(search)}');
      if(kat!=null&&kat!='Semua'&&kat.isNotEmpty) qp.add('kategori=${Uri.encodeComponent(kat)}');
      if(qp.isNotEmpty) url+='?${qp.join('&')}';
      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15));
      setState(() { produk = json.decode(res.body); loading=false; });
    } catch (e) { setState(() => loading=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaCream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: warnaUtama,
            actions: [Padding(padding: EdgeInsets.only(right:12), child: IconButton(icon: Icon(Icons.receipt_long, color: warnaEmas), onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>CekOrderPage()))))],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                double top = constraints.biggest.height;
                double percent = ((top - kToolbarHeight) / (110 - kToolbarHeight)).clamp(0.0, 1.0);
                return FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: EdgeInsets.only(bottom:12),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppConfig.namaToko, style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white, fontSize: 18 + (2*percent))),
                      Opacity(opacity: percent, child: Padding(padding: EdgeInsets.only(top:2), child: Text('SELAMAT DATANG DI TB MEKAR PAITON', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: warnaEmas, fontWeight: FontWeight.w600)))),
                    ],
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Container(width: double.infinity, padding: EdgeInsets.fromLTRB(16,16,16,12), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,2))]), child: Column(children: [
              TextField(controller: searchCtrl, decoration: InputDecoration(hintText: 'Cari semen, cat, besi klasik...', hintStyle: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic), prefixIcon: Icon(Icons.search, color: warnaUtama), filled: true, fillColor: warnaCream, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(vertical:12)), onChanged: (v)=>getProduk(search: v, kat: kategoriDipilih)),
              SizedBox(height:12),
              SizedBox(height:38, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: kategori.length, itemBuilder: (ctx,i){ bool aktif=kategoriDipilih==kategori[i]; return Padding(padding: EdgeInsets.only(right:8), child: ChoiceChip(label: Text(kategori[i].toUpperCase(), style: TextStyle(fontSize:11, fontWeight: aktif?FontWeight.bold:FontWeight.w500, letterSpacing:0.8)), selected: aktif, selectedColor: warnaUtama, backgroundColor: Colors.white, labelStyle: TextStyle(color: aktif?Colors.white:warnaUtama), shape: StadiumBorder(side: BorderSide(color: aktif?warnaUtama:warnaUtama.withOpacity(0.2))), onSelected: (s){ setState(()=>kategoriDipilih=kategori[i]); getProduk(search: searchCtrl.text, kat: kategori[i]); })); })),
            ])),
          ),
          SliverPadding(
            padding: EdgeInsets.all(14),
            sliver: loading? SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: warnaUtama))))
            : produk.isEmpty? SliverToBoxAdapter(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, size:60, color: Colors.grey[300]), SizedBox(height:12), Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey[600]))])))
            : SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 14, mainAxisSpacing: 14),
                delegate: SliverChildBuilderDelegate((ctx,i){
                  final p=produk[i];
                  int hargaUmum = parseHarga(p['harga_umum']??p['harga']);
                  String formatRibuan(int angka)=>angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m)=>'${m[1]}.');
                  String hargaDisplay = hargaUmum==0?'PILIH VARIAN':'Rp ${formatRibuan(hargaUmum)}';
                  bool isViral = (p['terlaris']??0) > 10;
                  return GestureDetector(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>ProdukDetailPage(produk: p))), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius:12, offset: Offset(0,6))], border: Border.all(color: warnaEmas.withOpacity(0.15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex:5, child: Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(18)), child: Image.network(p['foto']??'', width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: warnaCream, child: Icon(Icons.image, size:40, color: warnaUtama.withOpacity(0.3))))),
                      if(isViral) Positioned(top:8, left:8, child: Container(padding: EdgeInsets.symmetric(horizontal:8, vertical:3), decoration: BoxDecoration(color: Colors.red[700], borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.local_fire_department, size:12, color: Colors.white), SizedBox(width:3), Text('VIRAL', style: TextStyle(color: Colors.white, fontSize:9, fontWeight: FontWeight.bold))]))),
                      Positioned(top:8, right:8, child: InkWell(onTap: ()=>shareProduk(context,p), child: Container(padding: EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle), child: Icon(Icons.share, size:14, color: warnaUtama)))),
                    ])),
                    Expanded(flex:4, child: Padding(padding: EdgeInsets.fromLTRB(10,10,10,8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['nama'], maxLines:2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize:13, height:1.2, color: Color(0xFF2D2D2D))),
                      Spacer(),
                      Text(hargaDisplay, style: TextStyle(color: warnaUtama, fontWeight: FontWeight.w900, fontSize:14, fontFamily: 'Serif')),
                      Text('${p['satuan']??'sak'} • Stok ${p['stok']}', style: TextStyle(fontSize:10, color: Colors.grey[500], letterSpacing:0.3)),
                      SizedBox(height:6),
                      Container(width: double.infinity, height:32, decoration: BoxDecoration(color: warnaUtama, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(hargaUmum==0?'LIHAT VARIAN':'TAMBAH +', style: TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.bold, letterSpacing:1)))),
                    ]))),
                  ])));
                }, childCount: produk.length),
              ),
          ),
        ],
      ),
      floatingActionButton: Consumer<CartProvider>(builder: (ctx,cart,child)=> Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: warnaUtama.withOpacity(0.3), blurRadius:12, offset: Offset(0,6))], borderRadius: BorderRadius.circular(30)), child: FloatingActionButton.extended(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>HalamanCheckout())), backgroundColor: warnaUtama, icon: badges.Badge(badgeContent: Text(cart.totalItem.toString(), style: TextStyle(color: Colors.white, fontSize:10)), showBadge: cart.totalItem>0, badgeStyle: badges.BadgeStyle(badgeColor: warnaEmas), child: Icon(Icons.shopping_bag_outlined, color: Colors.white)), label: Text('Rp ${cart.totalHarga}', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing:0.5))))),
    );
  }
}