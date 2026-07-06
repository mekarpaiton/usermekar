// File khusus untuk Web (menggunakan paket resmi web bawaan Flutter terbaru)
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void putarAudioSukses() async {
  try {
    final ctx = web.AudioContext();
    
    // 1. Nada Ting-Ting (Bagian Pertama)
    final osc1 = ctx.createOscillator(); 
    final gain1 = ctx.createGain();
    osc1.type = 'sine'; 
    osc1.frequency.setValueAtTime(523.25, ctx.currentTime);
    gain1.gain.setValueAtTime(0.15, ctx.currentTime);
    gain1.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
    osc1.connect(gain1); 
    gain1.connect(ctx.destination);
    osc1.start(); 
    osc1.stop(ctx.currentTime + 0.15);
    
    // Solusi Modern: Mengganti window.setTimeout pakai Future.delayed asli Dart
    await Future.delayed(const Duration(milliseconds: 100));

    // Nada Ting-Ting (Bagian Kedua)
    final osc2 = ctx.createOscillator(); 
    final gain2 = ctx.createGain();
    osc2.type = 'sine'; 
    osc2.frequency.setValueAtTime(659.25, ctx.currentTime);
    gain2.gain.setValueAtTime(0.2, ctx.currentTime);
    gain2.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
    osc2.connect(gain2); 
    gain2.connect(ctx.destination);
    osc2.start(); 
    osc2.stop(ctx.currentTime + 0.3);

    await Future.delayed(const Duration(milliseconds: 400));

    // 2. Asisten Google berbicara ke Pelanggan
    final synth = web.window.speechSynthesis;
    synth.cancel();
    
    final ucapan = web.SpeechSynthesisUtterance("Orderan sukses bos! Silakan klik kirim di WhatsApp ya.");
    ucapan.lang = "id-ID";
    ucapan.rate = 1.0;
    synth.speak(ucapan);
    
  } catch (e) {
    print('Audio/Speech tidak didukung atau diblokir oleh browser: \$e');
  }
}
