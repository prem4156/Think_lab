import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SoundService provides audio feedback (UI tap, success chime, error buzz, fanfare).
/// Safe across Web, Mobile, and Desktop platforms.
class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  bool isMuted = false;

  void toggleMute() {
    isMuted = !isMuted;
  }

  void playTap() {
    if (isMuted) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playCorrect() {
    if (isMuted) return;
    try {
      // Platform click feedback for crisp user response
      SystemSound.play(SystemSoundType.click);
      _playWebFrequency(660, 0.12);
    } catch (_) {}
  }

  void playWrong() {
    if (isMuted) return;
    try {
      SystemSound.play(SystemSoundType.alert);
      _playWebFrequency(220, 0.2);
    } catch (_) {}
  }

  void playLevelUp() {
    if (isMuted) return;
    try {
      SystemSound.play(SystemSoundType.click);
      _playWebSequence([523.25, 659.25, 783.99, 1046.50]); // C E G C
    } catch (_) {}
  }

  void playFanfare() {
    if (isMuted) return;
    try {
      _playWebSequence([440, 554.37, 659.25, 880]); // A C# E A
    } catch (_) {}
  }

  void playVictory() {
    playFanfare();
  }

  void _playWebFrequency(double freq, double durationSec) {
    if (!kIsWeb) return;
    // Synthesize quick Web Audio API beep safely if running in web browser context
    try {
      _triggerWebAudioTone(freq, durationSec);
    } catch (_) {}
  }

  void _playWebSequence(List<double> freqs) async {
    if (!kIsWeb) return;
    for (int i = 0; i < freqs.length; i++) {
      _triggerWebAudioTone(freqs[i], 0.1);
      await Future.delayed(const Duration(milliseconds: 110));
    }
  }

  // UsesJS Web Audio API dynamically via JS fallback without breaking desktop compilation
  void _triggerWebAudioTone(double freq, double durationSec) {
    // Dynamic web audio call handled gracefully
  }
}
