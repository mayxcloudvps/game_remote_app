import 'package:flutter/material.dart';

void main() {
  runApp(const MayxCloudGamingApp());
}

class MayxCloudGamingApp extends StatelessWidget {
  const MayxCloudGamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MÂYX Cloud Gaming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const StreamViewerScreen(),
    );
  }
}

class StreamViewerScreen extends StatefulWidget {
  const StreamViewerScreen({super.key});

  @override
  State<StreamViewerScreen> createState() => _StreamViewerScreenState();
}

class _StreamViewerScreenState extends State<StreamViewerScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MÂYX Cloud Gaming Client'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isConnected) ...[
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ IP Server',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF0284C7),
                ),
                onPressed: () {
                  setState(() {
                    _isConnected = true;
                  });
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('KẾT NỐI SERVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Đang hiển thị màn hình Stream từ Server...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    _isConnected = false;
                  });
                },
                child: const Text('NGẮT KẾT NỐI'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
