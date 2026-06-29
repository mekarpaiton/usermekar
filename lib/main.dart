import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/cart_item.dart';
import 'pages/halaman_checkout.dart';
import 'package:badges/badges.dart' as badges;

const String baseUrl = 'https://abahkhuzai.pythonanywhere.com';
const String waAdmin = '628123453941';
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
        title: 'TB. MEKAR',
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
        title: const Text(
          'TB. MEKAR',
          style: TextStyle(
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
  List kategori = ['Semua', 'Semen', 'Cat', 'Pipa', 'Besi', 'Keramik']; // ← DIEDIT: Tambah list kategori
  String kategoriDipilih = 'Semua'; // ← DIEDIT: Tambah state kategori
  bool loading = true;
  TextEditingController searchController = TextEditingController(); // ← DIEDIT: Tambah controller search

  @override
  void initState() {
    super.initState();
    getProduk();
  }

  // ← DIEDIT: Function getProduk diubah total biar support search + kategori
  Future<void> getProduk({String? search, String? kategori}) async {
    setState(() => loading = true);
    try {
      String url = '$baseUrl/api/produk?';
      if (search!= null && search.isNotEmpty) url += 'search=$search&';
      if (kategori!= null && kategori!= 'Semua') url += 'kategori=$kategori';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          produk = json.decode(res.body);
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void chatAdmin() async {
    final url = Uri.parse('https://wa.me/$waAdmin?text=Halo TB. MEKAR, saya mau tanya produk');
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
            const Text('TB. MEKAR'),
          ],
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (ctx, cart, child) => badges.Badge(
              showBadge: cart.totalItem > 0,
              badgeContent: Text(
                cart.totalItem.toString(),
                style: TextStyle(color: Colors.white),
              ),
              child: IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => HalamanCheckout()),
                  );
                },
              ),
            ),
          ),
          IconButton(onPressed: chatAdmin, icon: const Icon(Icons.chat)),
          SizedBox(width: 8),
        ],
      ),
      // ← DIEDIT: Body dibungkus Column biar bisa tambah Search + Kategori di atas ListView
      body: Column(
        children: [
          // ← DIEDIT: 1. TAMBAH SEARCH BAR
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari semen, cat, pipa...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                        icon: Icon(Icons.clear),
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

          // ← DIEDIT: 2. TAMBAH CHIP KATEGORI
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

          // ← DIEDIT: 3. LIST PRODUK DIBUNGKUS Expanded
          Expanded(
            child: loading
          ? const Center(child: CircularProgressIndicator(color: warnaUtama))
              : produk.isEmpty
            ? const Center(child: Text('Produk tidak ditemukan', style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    itemCount: produk.length,
                    itemBuilder: (c, i) {
                      final p = produk[i];
                      final hargaData = p['harga'];
                      final hargaMap = hargaData is String? json.decode(hargaData) : hargaData;
                      final hargaPertama = hargaMap.values.first;
                      final stok = p['stok']?? 0; // ← DIEDIT: Tambah stok

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ← DIEDIT: Margin dikecilin
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p['foto'], // ← DIEDIT: 'gambar' jadi 'foto' biar sesuai DB
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          ),
                          title: Text(
                            p['nama'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Rp $hargaPertama / ${p['satuan']} | Stok: $stok'), // ← DIEDIT: Tambah stok
                          trailing: IconButton(
                            icon: Icon(Icons.add_shopping_cart, color: stok == 0? Colors.grey : warnaUtama), // ← DIEDIT: Disable kalo stok 0
                            onPressed: stok == 0? null : () { // ← DIEDIT: Disable kalo stok 0
                              Provider.of<CartProvider>(context, listen: false).addItem(
                                p['id'].toString(),
                                p['nama'],
                                int.parse(hargaPertama.toString()),
                                p['foto'], // ← DIEDIT: 'gambar' jadi 'foto'
                              );
                              ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ← DIEDIT: Biar snackbar nggak numpuk
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${p['nama']} ditambahkan ke keranjang'),
                                  duration: Duration(seconds: 1),
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
        ],
      ),
      
    );
  }
}