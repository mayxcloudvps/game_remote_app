import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Khóa màn hình ngang khi chơi game trên Android
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const GameRemoteApp());
}

class GameRemoteApp extends StatelessWidget {
  const GameRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConnectScreen(),
    );
  }
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.10");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("GAME REMOTE PLAY", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nhập IP Server PC",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RemoteScreen(ip: _ipController.text),
                    ),
                  );
                },
                child: const Text("KẾT NỐI", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RemoteScreen extends StatefulWidget {
  final String ip;
  const RemoteScreen({super.key, required this.ip});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  WebSocketChannel? _channel;
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://${widget.ip}:8765'));
      _channel!.stream.listen((data) {
        setState(() {
          _currentFrame = Uint8List.fromList(data);
        });
      }, onError: (err) {
        print("Lỗi kết nối: $err");
      });
    } catch (e) {
      print("Không thể kết nối: $e");
    }
  }

  void _sendInput(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Luồng Màn hình Game
          Center(
            child: _currentFrame != null
                ? Image.memory(
                    _currentFrame!,
                    gaplessPlayback: true,
                    fit: BoxFit.contain,
                  )
                : const CircularProgressIndicator(color: Colors.green),
          ),

          // 2. Cảm ứng Chuột trên màn hình (Touchpad / Click)
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                // Gửi độ dời chuột
                _sendInput({
                  "type": "mousedelta",
                  "dx": details.delta.dx,
                  "dy": details.delta.dy,
                });
              },
              onTapDown: (_) => _sendInput({"type": "mousedown", "button": 0}),
              onTapUp: (_) => _sendInput({"type": "mouseup", "button": 0}),
              onSecondaryTapDown: (_) => _sendInput({"type": "mousedown", "button": 2}),
              onSecondaryTapUp: (_) => _sendInput({"type": "mouseup", "button": 2}),
            ),
          ),

          // 3. Phím Joystick ảo (Bên trái màn hình Android)
          Positioned(
            left: 30,
            bottom: 30,
            child: Joystick(
              mode: JoystickMode.all,
              listener: (details) {
                _sendInput({
                  "type": "joystick",
                  "x": details.x,
                  "y": details.y,
                });
              },
            ),
          ),

          // 4. Các Nút bấm Gamepad ảo A, B, X, Y (Bên phải màn hình Android)
          Positioned(
            right: 40,
            bottom: 40,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  _buildPadButton("A", Alignment.bottomCenter),
                  _buildPadButton("Y", Alignment.topCenter),
                  _buildPadButton("X", Alignment.centerLeft),
                  _buildPadButton("B", Alignment.centerRight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton(String label, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTapDown: (_) => _sendInput({"type": "gamepad_button", "button": label, "pressed": true}),
        onTapUp: (_) => _sendInput({"type": "gamepad_button", "button": label, "pressed": false}),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Center(
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
