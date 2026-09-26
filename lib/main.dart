import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Ẩn thanh điều hướng và thanh trạng thái để tối ưu không gian hiển thị Stream Game
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Khóa màn hình xoay ngang (Landscape) cho trải nghiệm Cloud Gaming
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
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          // Hiển thị khung Stream Game sạch sẽ, không phím ảo, không control overlay
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Center(
                child: Text(
                  'MÂYX CLOUD GAMING - STREAM VIEW',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
