// lib/pages/web_audio_web.dart - FIX FINAL NO ERROR WASM
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void registerWebAudio() {}

void putarAudioSukses() {
  try {
    final ctx = web.AudioContext();
    if (ctx.state == 'suspended') {
      ctx.resume();
    }
    final now = ctx.currentTime;

    final o1 = ctx.createOscillator();
    o1.type = 'sine';
    o1.frequency.setValueAtTime(523.25, now);
    final g1 = ctx.createGain();
    g1.gain.setValueAtTime(0.15, now);
    g1.gain.exponentialRampToValueAtTime(0.01, now + 0.15);
    o1.connect(g1);
    g1.connect(ctx.destination);
    o1.start();
    o1.stop(now + 0.15);

    final o2 = ctx.createOscillator();
    o2.type = 'sine';
    o2.frequency.setValueAtTime(659.25, now + 0.12);
    final g2 = ctx.createGain();
    g2.gain.setValueAtTime(0.2, now + 0.12);
    g2.gain.exponentialRampToValueAtTime(0.01, now + 0.42);
    o2.connect(g2);
    g2.connect(ctx.destination);
    o2.start(now + 0.12);
    o2.stop(now + 0.42);

    // FIX PALING PENTING - FORMAT BARU PACKAGE:WEB
    web.window.setTimeout(
      (() {
        try {
          final synth = web.window.speechSynthesis;
          synth.cancel();
          final ucapan = web.SpeechSynthesisUtterance(
              "Orderan sukses bos! Silakan klik kirim di WhatsApp ya.");
          ucapan.lang = "id-ID";
          synth.speak(ucapan);
        } catch (_) {}
      }).toJS,
      500,
    );
  } catch (e) {
    // silent
  }
}

void putarAudioGagal() {}