import 'dart:js_interop';

@JS('eval')
external void _jsEval(String code);

void playKioskBeep({required bool success}) {
  try {
    final freq = success ? 880 : 220;
    final type = success ? 'sine' : 'square';
    final dur = success ? 0.25 : 0.5;
    final vol = success ? 0.2 : 0.15;
    _jsEval('''
(function() {
  try {
    var ctx = new (window.AudioContext || window.webkitAudioContext)();
    var osc = ctx.createOscillator();
    var gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = $freq;
    osc.type = "$type";
    gain.gain.setValueAtTime($vol, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + $dur);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + $dur);
  } catch(e) {}
})()
''');
  } catch (_) {}
}
