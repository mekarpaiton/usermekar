// File khusus untuk Web (menggunakan library web resmi Flutter)
import 'dart:web_gl' as unsafe_avoid_warning; 
import 'package:web/web.dart' as web; 

void putarAudioSukses() {
  try {
    final ctx = web.AudioContext();

    // 1. Nada Ting-Ting
    final osc1 = ctx.createOscillator(); final gain1 = ctx.createGain();
    osc1.type = 'sine'; osc1.frequency.setValueAtTime(523.25, ctx.currentTime);
    gain1.gain.setValueAtTime(0.15, ctx.currentTime);
    gain1.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
    osc1.connect(gain1); gain1.connect(ctx.destination);
    osc1.start(); osc1.stop(ctx.currentTime + 0.15);

    web.window.setTimeout(() {
      final osc2 = ctx.createOscillator(); final gain2 = ctx.createGain();
      osc2.type = 'sine'; osc2.frequency.setValueAtTime(659.25, ctx.currentTime);
      gain2.gain.setValueAtTime(0.2, ctx.currentTime);
      gain2.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
      osc2.connect(gain2); gain2.connect(ctx.destination);
      osc2.start(); osc2.stop(ctx.currentTime + 0.3);
    }, 100);

    // 2. Teks Suara Google
    web.window.setTimeout(() {
      final synth = web.window.speechSynthesis;
      synth.cancel();
      final ucapan = web.SpeechSynthesisUtterance("Orderan sukses bos! Silakan klik kirim di WhatsApp ya.");
      ucapan.lang = "id-ID";
      ucapan.rate = 1.0;
      synth.speak(ucapan);
    }, 500);
  } catch (e) {
    print('Audio tidak didukung di browser ini');
  }
}
