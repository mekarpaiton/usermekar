import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('pemicuSuaraSukses')
external set _pemicuSuaraSukses(JSFunction f);

void registerWebAudio() {
  _pemicuSuaraSukses = putarAudioSukses.toJS;
}

@JSExport()
void putarAudioSukses() {
  try {
    final ctx = web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
    final now = ctx.currentTime;
    final o1 = ctx.createOscillator()..type='sine'..frequency.setValueAtTime(523.25, now);
    final g1 = ctx.createGain()..gain.setValueAtTime(0.15, now);
    g1.gain.exponentialRampToValueAtTime(0.01, now+0.15);
    o1.connect(g1); g1.connect(ctx.destination); o1.start(); o1.stop(now+0.15);
    final o2 = ctx.createOscillator()..type='sine'..frequency.setValueAtTime(659.25, now+0.12);
    final g2 = ctx.createGain()..gain.setValueAtTime(0.2, now+0.12);
    g2.gain.exponentialRampToValueAtTime(0.01, now+0.42);
    o2.connect(g2); g2.connect(ctx.destination); o2.start(now+0.12); o2.stop(now+0.42);
    web.window.setTimeout((JSAny _) {
      final s = web.window.speechSynthesis; s.cancel();
      s.speak(web.SpeechSynthesisUtterance("Orderan sukses bos! Silakan klik kirim di WhatsApp ya.")..lang="id-ID");
    }.toJS, 500);
  } catch (_) {}
}