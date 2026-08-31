import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../l10n/strings.dart';
import 'gemini_client.dart';

enum VoiceAssistantError { micPermission, network, emptyRecording, noAnswer, generic }

class VoiceAssistantService {
  static const _systemPrompt =
      "You are Handora AI, a helpful voice assistant for Indian artisans who sell "
      "handicrafts on ONDC. Listen carefully to the audio clip below. The user is "
      "speaking a question or request — it may be in Hindi, English, or Hinglish. "
      "Understand exactly what they are asking, then provide a direct, specific, "
      "and helpful answer to THAT question. Do NOT give a generic greeting or "
      "introduction — jump straight into answering the user's actual query. "
      "Reply in the same language the user spoke in.";

  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final ValueNotifier<bool> ttsPaused = ValueNotifier(false);

  bool _ttsReady = false;
  String? _recordingPath;

  VoiceAssistantService() {
    _tts.setStartHandler(() {
      isSpeaking.value = true;
      ttsPaused.value = false;
    });
    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
      ttsPaused.value = false;
    });
    _tts.setCancelHandler(() {
      isSpeaking.value = false;
      ttsPaused.value = false;
    });
    _tts.setPauseHandler(() {
      isSpeaking.value = false;
      ttsPaused.value = true;
    });
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      isSpeaking.value = false;
      ttsPaused.value = false;
    });

    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS init warning: $e');
      _ttsReady = false;
    }
  }

  Future<void> startRecording() async {
    final granted = await _recorder.hasPermission();
    if (!granted) throw VoiceAssistantError.micPermission;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/handora_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    _recordingPath = path;
  }

  Future<double> getMicLevel() async {
    if (_recordingPath == null) return 0;
    try {
      final amp = await _recorder.getAmplitude();
      return ((amp.current + 45) / 45).clamp(0.0, 1.0).toDouble();
    } catch (_) {
      return 0;
    }
  }

  Future<String> stopRecordingAndAsk() async {
    final path = await _recorder.stop();
    _recordingPath = null;
    if (path == null) throw VoiceAssistantError.emptyRecording;

    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw VoiceAssistantError.emptyRecording;
      try { await file.delete(); } catch (_) {}
      return await _askGemini(bytes);
    } on FileSystemException {
      throw VoiceAssistantError.emptyRecording;
    }
  }

  Future<void> cancelRecording() async {
    final path = await _recorder.stop();
    _recordingPath = null;
    if (path != null) {
      try { await File(path).delete(); } catch (_) {}
    }
  }

  Future<String> _askGemini(List<int> audioBytes) async {
    try {
      final body = {
        "system_instruction": {
          "parts": [{"text": _systemPrompt}]
        },
        "contents": [
          {
            "parts": [
              {
                "text": "Listen carefully to the user's spoken voice query in this "
                    "audio clip. Understand what they are asking — it could be in "
                    "Hindi, English, or Hinglish. Provide a direct, helpful answer "
                    "to their specific question. Do NOT introduce yourself or give "
                    "a generic greeting."
              },
              {
                "inline_data": {
                  "mime_type": "audio/aac",
                  "data": base64Encode(audioBytes),
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "thinkingConfig": {"thinkingBudget": 0},
        },
      };

      final response = await GeminiClient.generateContent(
        body,
        timeout: const Duration(seconds: 45),
      );

      if (response.statusCode != 200) {
        debugPrint('Gemini voice error ${response.statusCode}: ${response.body}');
        throw VoiceAssistantError.generic;
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw VoiceAssistantError.noAnswer;
      }

      final parts = candidates[0]['content']['parts'] as List;
      final text = parts
          .where((p) => p['text'] != null)
          .map((p) => p['text'] as String)
          .join()
          .trim();
      if (text.isEmpty) throw VoiceAssistantError.noAnswer;
      return text;
    } on VoiceAssistantError {
      rethrow;
    } on TimeoutException {
      throw VoiceAssistantError.network;
    } on SocketException {
      throw VoiceAssistantError.network;
    } on http.ClientException {
      throw VoiceAssistantError.network;
    } catch (_) {
      throw VoiceAssistantError.generic;
    }
  }

  Future<void> speak(String text, {required Language language}) async {
    try { await _tts.stop(); } catch (_) {}

    if (!_ttsReady) await _initTts();

    var langCode =
        language == Language.hi || RegExp(r'[\u0900-\u097F]').hasMatch(text)
            ? 'hi-IN'
            : 'en-IN';

    // Check if the chosen language is available on this device
    try {
      final available = await _tts.isLanguageAvailable(langCode);
      if (available != true) {
        langCode = 'en-IN';
        final enAvailable = await _tts.isLanguageAvailable('en-IN');
        if (enAvailable != true) langCode = 'en-US';
      }
    } catch (_) {
      langCode = 'en-IN';
    }

    await _tts.setLanguage(langCode);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> pauseSpeaking() async {
    try { await _tts.pause(); } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try { await _tts.stop(); } catch (_) {}
  }

  Future<void> dispose() async {
    if (_recordingPath != null) {
      try { await _recorder.cancel(); } catch (_) {}
    }
    try { await _tts.stop(); } catch (_) {}
    try { await _recorder.dispose(); } catch (_) {}
  }
}
