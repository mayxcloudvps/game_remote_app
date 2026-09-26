import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyCustomBrandApp());
}

class MyCustomBrandApp extends StatelessWidget {
  const MyCustomBrandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MÂYX CLOUD GAMING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.10");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16161E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 15)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, size: 50, color: Colors.cyanAccent),
              const SizedBox(height: 10),
              const Text(
                "MÂYX CLOUD GAMING",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nhập IP PC Server",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameStreamScreen(serverIp: _ipController.text),
                      ),
                    );
                  },
                  child: const Text("VÀO GAME NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GameStreamScreen extends StatefulWidget {
  final String serverIp;
  const GameStreamScreen({super.key, required this.serverIp});

  @override
  State<GameStreamScreen> createState() => _GameStreamScreenState();
}

class _GameStreamScreenState extends State<GameStreamScreen> {
  RawDatagramSocket? _inputSocket;
  RawDatagramSocket? _videoSocket;
  Uint8List? _frameBytes;

  @override
  void initState() {
    super.initState();
    _initSockets();
  }

  void _initSockets() async {
    // Socket gửi phím/chuột
    _inputSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    // Socket nhận video
    _videoSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 9999);
    _videoSocket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _videoSocket!.receive();
        if (dg != null) {
          setState(() {
            _frameBytes = dg.data;
          });
        }
      }
    });

    // Ping khởi động gửi dữ liệu
    _sendInput({"type": "ping"});
  }

  void _sendInput(Map<String, dynamic> data) {
    if (_inputSocket != null) {
      String jsonStr = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonStr);
      _inputSocket!.send(bytes, InternetAddress(widget.serverIp), 8888);
    }
  }

  @override
  void dispose() {
    _inputSocket?.close();
    _videoSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Luồng Màn hình
          Center(
            child: _frameBytes != null
                ? Image.memory(_frameBytes!, gaplessPlayback: true, fit: BoxFit.contain)
                : const CircularProgressIndicator(color: Colors.cyanAccent),
          ),

          // 2. Vùng di chuyển chuột / Xoay camera FPS 360 độ
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                _sendInput({
                  "type": "mousedelta",
                  "dx": details.delta.dx * 2.5, // Gia tốc di chuột
                  "dy": details.delta.dy * 2.5,
                });
              },
            ),
          ),

          // 3. Cụm Bắn & Ngắm (Bên phải màn hình)
          Positioned(
            right: 120,
            bottom: 40,
            child: GestureDetector(
              onTapDown: (_) => _sendInput({"type": "mouseclick", "button": 0, "pressed": true}),
              onTapUp: (_) => _sendInput({"type": "mouseclick", "button": 0, "pressed": false}),
              child: _buildCircleBtn("SHOOT", Colors.redAccent),
            ),
          ),
          Positioned(
            right: 40,
            bottom: 110,
            child: GestureDetector(
              onTapDown: (_) => _sendInput({"type": "mouseclick", "button": 1, "pressed": true}),
              onTapUp: (_) => _sendInput({"type": "mouseclick", "button": 1, "pressed": false}),
              child: _buildCircleBtn("AIM", Colors.blueAccent),
            ),
          ),

          // 4. Joystick Di chuyển WASD (Bên trái)
          Positioned(
            left: 40,
            bottom: 40,
            child: Joystick(
              mode: JoystickMode.all,
              listener: (details) {
                // Xử lý di chuyển phím WASD dựa theo Joystick
                if (details.y < -0.5) _sendInput({"type": "key", "key": "w", "pressed": true});
                if (details.y > 0.5) _sendInput({"type": "key", "key": "s", "pressed": true});
                if (details.x < -0.5) _sendInput({"type": "key", "key": "a", "pressed": true});
                if (details.x > 0.5) _sendInput({"type": "key", "key": "d", "pressed": true});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(String label, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
