import 'dart:async';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TranscriptionService {
  final _audioRecorder = AudioRecorder();
  WebSocketChannel? _channel;

  // StreamController to pipe transcripts to your UI
  final _textController = StreamController<String>.broadcast();
  Stream<String> get transcriptionStream => _textController.stream;

  final String backendUrl = "ws://localhost:8000/ws/transcribe";

  Future<void> startStreaming() async {
    try {
      // 1. Check Permissions
      if (!(await _audioRecorder.hasPermission())) {
        print("❌ Mic permission denied");
        return;
      }

      // 2. Connect to your Python Backend
      _channel = WebSocketChannel.connect(Uri.parse(backendUrl));
      print("🔌 Connected to Python Backend");

      // 3. Listen for text coming BACK from the server
      _channel!.stream.listen(
        (message) {
          // The backend sends us the transcript as a simple string
          print("🎯 Transcript received: $message");
          _textController.add(message);
        },
        onDone: () => print("🔌 Connection to backend closed"),
        onError: (err) => print("🚨 WebSocket Error: $err"),
      );

      // 4. Start Mic Stream (PCM 16-bit, 16kHz)
      final micStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // 5. Pipe Mic Data directly to the Backend
      micStream.listen((newData) {
        if (_channel != null) {
          // Sending raw binary data (List<int>)
          _channel!.sink.add(newData);
        }
      });
    } catch (e) {
      print("🚨 Failed to start streaming: $e");
    }
  }

  Future<void> stopStreaming() async {
    print("🛑 Stopping stream...");
    await _audioRecorder.stop();
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _textController.close();
    _channel?.sink.close();
  }
}
