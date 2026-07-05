import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'pages/halaman_checkout.dart';
import 'pages/cek_order_page.dart';
import 'pages/produk_detail_page.dart';
import 'config.dart';

const Color warnaUtama = Color(0xFF7F00FF);

void main() {
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
          appBarTheme: const AppBarTheme(
            backgroundColor: warnaUtama,
            foregroundColor: Colors.white,
            elevation: 0,
          ), // tutup AppBarTheme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: warnaUtama,
              foregroundColor: Colors.white,
            ), // tutup styleFrom
          ), // tutup ElevatedButtonThemeData
        ), // tutup ThemeData
        home: const SplashScreen(),
      ), // tutup MaterialApp
    ); // tutup ChangeNotifierProvider
  } // tutup build
} // tutup TBMekarApp


// =================================================================
// SPLASH SCREEN
// =================================================================
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

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _alignmentAnimation = Tween<Alignment>(
      begin: const Alignment(2.2, 3.2),
      end: Alignment.center,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAtCenter = true;
            _isClicked = true;
          });
          _rippleController.forward();
        }
      }
    });

    _rippleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F00FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppConfig.namaToko,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)]
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splashmekar.png',
              fit: BoxFit.cover,
            ),
          ),
          if (_isClicked)
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return Center(
                  child: CustomPaint(
                    painter: ShockwavePainter(progress: _rippleController.value),
                    size: const Size(200, 200),
                  ),
                );
              },
            ),
          AnimatedBuilder(
            animation: _alignmentAnimation,
            builder: (context, child) {
              return Align(
                alignment: _alignmentAnimation.value,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _isAtCenter
                  ? AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transformAlignment: Alignment.center,
                          transform: Matrix4.identity()..scale(_isClicked? 0.85 : 1.0),
                          child: const Text(
                            '📸',
                            key: ValueKey('finger_icon'),
                            style: TextStyle(fontSize: 60),
                          ),
                        )
                      : const Text(
                          '📷',
                          key: ValueKey('tools_icon'),
                          style: TextStyle(fontSize: 85),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ShockwavePainter extends CustomPainter {
  final double progress;
  ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint1 = Paint()
     ..color = const Color(0xff26a69a).withOpacity(1.0 - progress)
     ..style = PaintingStyle.stroke
     ..strokeWidth = 4.0 * (1.0 - progress);
    double radius1 = progress * 130;
    canvas.drawCircle(center, radius1, paint1);

    if (progress > 0.2) {
      final progress2 = (progress - 0.2) / 0.8;
      final paint2 = Paint()
       ..color = Colors.cyanAccent.withOpacity(1.0 - progress2)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2.5 * (1.0 - progress2);
      double radius2 = progress2 * 90;
      canvas.drawCircle(center, radius2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) {
    return oldDelegate.progress!= progress;
  }
}

// =================================================================
// HOME PAGE
// =================================================================
class HalamanKatalog extends StatefulWidget {
  const HalamanKatalog({super.key});
  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  List produk = [];
  List kategori = ['Semua'];
  String kategoriDipilih = 'Semua';
  bool loading = true;
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    getKategori();
    getProduk();
  }

  Future<void> getKategori() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/kategori'));
      final data = json.decode(res.body) as List;
      setState(() {
        kategori = ['Semua',...data.map((e) => e['nama'].toString())];
      });
    } catch (e) {
      print('Error kategori: $e');
    }
  }

  Future<void> getProduk({String? search, String? kat}) async {
    setState(() => loading = true);
    try {
      String url = '${AppConfig.baseUrl}/api/produk?';
      if (search!= null && search.isNotEmpty) url += 'q=$search&';
      if (kat!= null && kat!= 'Semua') url += 'kategori=$kat';

      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15));
      setState(() {
        produk = json.decode(res.body);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil produk: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.namaToko),
        backgroundColor: warnaUtama,
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => CekOrderPage())),
            tooltip: 'Cek Pesanan',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari semen, cat, besi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => getProduk(search: v, kat: kategoriDipilih),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: kategori.length,
              itemBuilder: (ctx, i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(kategori[i]),
                  selected: kategoriDipilih == kategori[i],
                  onSelected: (s) {
                    setState(() => kategoriDipilih = kategori[i]);
                    getProduk(search: searchCtrl.text, kat: kategori[i]);
                  },
                  selectedColor: warnaUtama,
                  labelStyle: TextStyle(
                    color: kategoriDipilih == kategori[i]? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
               ? Center(child: CircularProgressIndicator())
                : produk.isEmpty
                   ? Center(child: Text('Produk tidak ditemukan'))
                    : RefreshIndicator(
                        onRefresh: () => getProduk(kat: kategoriDipilih),
                        child: GridView.builder(
                          padding: EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: produk.length,
                          itemBuilder: (ctx, i) {
                            final p = produk[i];
                            final harga = p['harga_umum']['umum']?? 0;
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailProdukPage(produk: p),
                                ),
                              ),
                              child: Card(
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          p['foto']?? '',
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.image, size: 50),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['nama'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Rp ${harga.toString()} /${p['satuan']}',
                                            style: TextStyle(
                                              color: warnaUtama,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Stok: ${p['stok']}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Floating Cart
      floatingActionButton: Consumer<CartProvider>(
        builder: (ctx, cart, child) => FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => HalamanCheckout())),
          backgroundColor: warnaUtama,
          icon: Badge(
            label: Text(cart.totalItem.toString()),
            isLabelVisible: cart.totalItem > 0,
            child: Icon(Icons.shopping_cart),
          ),
          label: Text('Rp ${cart.totalHarga}'),
        ),
      ),
    );
  }
}
    );
  }
}