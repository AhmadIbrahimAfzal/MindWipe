import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound and Haptic feedback engine for MindWipe.
///
/// 🧠 LEARN:
/// - Plays custom tactile sound effects provided in [assets/audio/]:
///   1. [playWhoosh]: Smooth whoosh sound when a thought is deleted/cleared.
///   2. [playPop]: Crisp bubble pop sound when a thought is checked off / completed.
///   3. [playTick]: Rotary dial ratchet tick when turning through pages.
/// - Pairs every audio cue with corresponding high-contrast haptic vibrations.
class AudioFeedback {
  AudioFeedback._();

  static final AudioPlayer _whooshPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _popPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _tickPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static late final Uint8List _tickWav;
  static bool _initialized = false;

  /// Pre-initializes audio players and loads audio sources.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _tickWav = _generateTickWav();

    try {
      await _whooshPlayer.setSource(AssetSource('audio/whoosh.mp3'));
      await _popPlayer.setSource(AssetSource('audio/pop.mp3'));
    } catch (_) {}
  }

  /// Plays whoosh.mp3 and heavy haptic vibration when a thought is deleted.
  static Future<void> playWhoosh() async {
    HapticFeedback.heavyImpact();
    try {
      await _whooshPlayer.stop();
      await _whooshPlayer.play(AssetSource('audio/whoosh.mp3'), volume: 0.9);
    } catch (_) {}
  }

  /// Plays pop.mp3 and medium haptic vibration when a thought is checked off / completed.
  static Future<void> playPop() async {
    HapticFeedback.mediumImpact();
    try {
      await _popPlayer.stop();
      await _popPlayer.play(AssetSource('audio/pop.mp3'), volume: 0.85);
    } catch (_) {}
  }

  /// Plays a rotary jog dial ratchet tick when turning through pages.
  static Future<void> playTick() async {
    HapticFeedback.selectionClick();
    try {
      if (!_initialized) init();
      await _tickPlayer.stop();
      await _tickPlayer.play(BytesSource(_tickWav), volume: 0.4);
    } catch (_) {}
  }

  // ─── Procedural WAV Generator for Ratchet Tick ───────────────

  static Uint8List _generateTickWav() {
    const int sampleRate = 44100;
    const double duration = 0.012;
    final int totalSamples = (sampleRate * duration).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      final double env = exp(-t * 260.0);
      samples[i] = sin(2 * pi * 2400.0 * t) * env;
    }

    final int numSamples = samples.length;
    final int byteRate = sampleRate * 2;
    final int dataSize = numSamples * 2;
    final int fileSize = 36 + dataSize;
    final buffer = ByteData(44 + dataSize);

    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final sample = samples[i].clamp(-1.0, 1.0);
      final int intSample = (sample * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
