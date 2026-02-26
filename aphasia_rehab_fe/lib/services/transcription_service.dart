import 'dart:async';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TranscriptionResult {
  final String text;
  final double endOfTurnConfidence;
  final bool isEndOfTurn;

  TranscriptionResult({
    required this.text,
    required this.endOfTurnConfidence,
    required this.isEndOfTurn,
  });
}

class TranscriptionService {
  final _audioRecorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<List<int>>? _micSubscription;
  bool _isStopping = false;

  final _textController = StreamController<TranscriptionResult>.broadcast();
  Stream<TranscriptionResult> get transcriptionStream => _textController.stream;

  final String backendUrl = "ws://localhost:8000/ws/transcribe";

  Future<void> startStreaming() async {
    try {
      _isStopping = false; // Reset flag

      if (!(await _audioRecorder.hasPermission())) {
        print("❌ Mic permission denied");
        return;
      }

      _channel = WebSocketChannel.connect(Uri.parse(backendUrl));
      print("🔌 Connected to Python Backend");

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (!_textController.isClosed) {
              _textController.add(
                TranscriptionResult(
                  text: data['text'],
                  endOfTurnConfidence: (data['end_of_turn_confidence'] is num)
                      ? data['end_of_turn_confidence'].toDouble()
                      : 0.0,
                  isEndOfTurn: data['end_of_turn'] ?? false,
                ),
              );
            }
          } catch (e) {
            print("Error parsing transcript: $e");
          }
        },
        onDone: () => print("🔌 Connection to backend closed"),
        onError: (err) => print("🚨 WebSocket Error: $err"),
      );

      final micStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _micSubscription = micStream.listen((newData) {
        if (!_isStopping && _channel != null) {
          _channel!.sink.add(newData);
        }
      });
    } catch (e) {
      print("🚨 Failed to start streaming: $e");
    }
  }

  Future<void> stopStreaming() async {
    if (_isStopping) return;
    _isStopping = true;

    print("🛑 Stopping stream...");

    await _micSubscription?.cancel();
    _micSubscription = null;

    await _audioRecorder.stop();

    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    stopStreaming();
    _textController.close();
  }
}
