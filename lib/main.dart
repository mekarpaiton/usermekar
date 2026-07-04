import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/cart_item.dart';
import 'pages/halaman_checkout.dart';
import 'package:badges/badges.dart' as badges;
import 'config.dart'; // ← IMPORT CONFIG
import 'pages/cek_order_page.dart';

const Color warnaUtama = Color(0xFF7F00FF); // UNGU

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
        title: AppConfig.namaToko, // ← PAKE CONFIG
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          primaryColor: warnaUtama,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: warnaUtama,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: warnaUtama,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

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
          AppConfig.namaToko, // ← PAKE CONFIG
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

// =================================================================
// PELUKIS GELOMBANG KEJUT
// =================================================================
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
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List produk = [];
  List kategori = ['Semua', 'Semen', 'Cat', 'Pipa', 'Besi', 'Keramik', 'Lainnya'];
  String kategoriDipilih = 'Semua';
  bool loading = true;
  String errorMsg = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getProduk();
  }

  Future<void> getProduk({String? search, String? kategori}) async {
    if (mounted) setState(() { loading = true; errorMsg = ''; });
    try {
      String url = '${AppConfig.baseUrl}/api/produk?'; // ← GANTI PAKE CONFIG
      if (search!= null && search.isNotEmpty) url += 'search=$search&';
      if (kategori!= null && kategori!= 'Semua') url += 'kategori=$kategori';

      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (res.statusCode!= 200) throw Exception('Server error ${res.statusCode}');
      if (!res.headers['content-type']!.contains('application/json')) throw Exception('Response bukan JSON');

      setState(() {
        produk = json.decode(res.body);
        loading = false;
      });
    } catch (e) {
      print("KATALOG USER ERROR: $e");
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMsg = 'Gagal ambil produk. Cek koneksi internet';
      });
    }
  }

  void chatAdmin() async {
    final url = Uri.parse(AppConfig.linkWaPesan('Halo ${AppConfig.namaToko}, saya mau tanya produk')); // ← PAKE CONFIG
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logomekar.png', height: 35),
            const SizedBox(width: 10),
            Text(AppConfig.namaToko), // ← PAKE CONFIG
          ],
        ),
        actions: [
IconButton(
  icon: const Icon(Icons.receipt_long),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CekOrderPage()),
    );
  },
),
          Consumer<CartProvider>(
            builder: (ctx, cart, child) => badges.Badge(
              showBadge: cart.totalItem > 0,
              badgeContent: Text(
                cart.totalItem.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const HalamanCheckout()),
                  );
                },
              ),
            ),
          ),
          IconButton(onPressed: chatAdmin, icon: const Icon(Icons.chat)),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari semen, cat, pipa...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          getProduk(kategori: kategoriDipilih);
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => getProduk(search: value, kategori: kategoriDipilih),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: kategori.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(kategori[i]),
                  selected: kategoriDipilih == kategori[i],
                  onSelected: (selected) {
                    setState(() => kategoriDipilih = kategori[i]);
                    getProduk(search: searchController.text, kategori: kategori[i]);
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
          ? const Center(child: CircularProgressIndicator(color: warnaUtama))
              : errorMsg.isNotEmpty
             ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(errorMsg, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => getProduk(), child: const Text('Coba Lagi'))
                  ]))
                  : produk.isEmpty
                 ? const Center(child: Text('Produk tidak ditemukan', style: TextStyle(fontSize: 16)))
                      : RefreshIndicator(
                          onRefresh: () => getProduk(search: searchController.text, kategori: kategoriDipilih),
                          child: ListView.builder(
                            itemCount: produk.length,
                            itemBuilder: (c, i) {
                              final p = produk[i];
                              final hargaData = p['harga'];
                              Map hargaMap = {};
                              try {
                                hargaMap = hargaData is String? json.decode(hargaData) : hargaData;
                              } catch (e) {
                                hargaMap = {};
                              }
                              final hargaPertama = hargaMap.values.isNotEmpty? hargaMap.values.first : 0;
                              final stok = p['stok']?? 0;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      p['foto']?? '',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    p['nama']?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Rp $hargaPertama / ${p['satuan']?? ''} | Stok: $stok'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.add_shopping_cart, color: stok == 0? Colors.grey : warnaUtama),
                                    onPressed: stok == 0? null : () {
                                      Provider.of<CartProvider>(context, listen: false).addItem(
                                        p['id'].toString(),
                                        p['nama'],
                                        int.tryParse(hargaPertama.toString())?? 0,
                                        p['foto']?? '',
                                      );
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${p['nama']} ditambahkan ke keranjang'),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: warnaUtama,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
          ),
        ],
      ),
    );
  }
}