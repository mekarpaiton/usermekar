class AppConfig {
  // ======= EDIT BAGIAN INI AJA KALO MAU GANTI =======

  /// Base URL API Backend PythonAnywhere
  static const String baseUrl = 'https://abahkhuzai.pythonanywhere.com';

  /// Nomor WhatsApp Admin tanpa + dan tanpa 0 di depan
  static const String waAdmin = '628123453941';

  /// Nama Toko
  static const String namaToko = 'TB. MEKAR';

  /// Alamat Toko
  static const String alamatToko = 'Jalan Raya Paiton RT. 1 RW. 1, Karanganyar, Paiton, Probolinggo';

  /// Link Katalog Online Github Pages
  static const String linkKatalog = 'https://abahkhuzai.github.io/tbmekar.github.io/';

  /// API Key FreeImageHost buat upload foto
  static const String freeImageHostKey = '6d207e02198a847aa98d0a2a901485a5';

  // ======= HELPER / JANGAN EDIT KECUALI PAHAM =======

  /// Link WhatsApp tanpa pesan
  static String get linkWa => 'https://wa.me/$waAdmin';

  /// Link WhatsApp + pesan otomatis. Auto encode biar nggak macet
  static String linkWaPesan(String pesan) {
    final encoded = Uri.encodeComponent(pesan);
    return 'https://wa.me/$waAdmin?text=$encoded';
  }

  /// Link WhatsApp langsung ke App, bukan browser. Biar gak nyangkut. <-- TAMBAH INI
  static String linkWaApp(String pesan) {
    final encoded = Uri.encodeComponent(pesan);
    return 'whatsapp://send?phone=$waAdmin&text=$encoded';
  }
}