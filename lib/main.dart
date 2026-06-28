import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'https://abahkhuzai.pythonanywhere.com';
const String waAdmin = '628123453941';
const Color warnaUtama = Color(0xFF16A34A);

void main() {
  runApp(const TBMekarApp());
}

class TBMekarApp extends StatelessWidget {
  const TBMekarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB. MEKAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: warnaUtama,
        appBarTheme: const AppBarTheme(backgroundColor: warnaUtama),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: warnaUtama),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/splashmekar.png',
          width: MediaQuery.of(context).size.width * 0.8),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List produk = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getProduk();
  }

  Future<void> getProduk() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/produk'));
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
          IconButton(onPressed: chatAdmin, icon: const Icon(Icons.chat)),
        ],
      ),
      body: loading
         ? const Center(child: CircularProgressIndicator())
          : produk.isEmpty
             ? const Center(child: Text('Belum ada produk'))
              : ListView.builder(
                  itemCount: produk.length,
                  itemBuilder: (c, i) {
                    final p = produk[i];
                    final harga = json.decode(p['harga']);
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Rp ${harga.values.first} / ${p['satuan']}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            final text = 'Halo, saya mau pesan: ${p['nama']} - Rp ${harga.values.first}';
                            launchUrl(Uri.parse('https://wa.me/$waAdmin?text=$text'));
                          },
                          child: const Text('Pesan'),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: chatAdmin,
        backgroundColor: warnaUtama,
        icon: const Icon(Icons.chat),
        label: const Text('Chat Admin'),
      ),
    );
  }
}
