class AppConfig {
  static const String baseUrl = 'https://abahkhuzai.pythonanywhere.com';
  static const String waAdmin = '628123453941';
  static const String namaToko = 'TB. MEKAR';
  static const String alamatToko = 'Jalan Raya Paiton RT. 1 RW. 1, Karanganyar, Paiton, Probolinggo';
  static const String linkKatalog = 'https://mekarpaiton.github.io/usermekar'; // ← Ini yang bener
  
  static const String freeImageHostKey = '6d207e02198a847aa98d0a2a901485a5';

  static String get linkWa => 'https://wa.me/$waAdmin';

  static String linkWaPesan(String pesan) {
    final encoded = Uri.encodeComponent(pesan);
    return 'https://wa.me/$waAdmin?text=$encoded';
  }

  static String linkWaApp(String pesan) {
    final encoded = Uri.encodeComponent(pesan);
    return 'whatsapp://send?phone=$waAdmin&text=$encoded';
  }
}