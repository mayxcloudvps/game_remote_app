import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fullscreen ẩn thanh điều hướng
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Khóa màn hình xoay ngang
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MayxCloudGamingApp());
  });
}

class MayxCloudGamingApp extends StatelessWidget {
  const MayxCloudGamingApp({Super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MÂYX CLOUD GAMING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const StreamViewerScreen(),
    );
  }
}

class StreamViewerScreen extends StatefulWidget {
  const StreamViewerScreen({Super.key});

  @override
  State<StreamViewerScreen> createState() => _StreamViewerScreenState();
}

class _StreamViewerScreenState extends State<StreamViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon MÂYX CLOUD nổi bật ở giữa màn hình chờ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF06B6D4), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.cloud_queue,
                  size: 64,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MÂYX CLOUD GAMING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đang kết nối tới Server...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
