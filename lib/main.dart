import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MayxCloudGamingApp());
}

class MayxCloudGamingApp extends StatelessWidget {
  const MayxCloudGamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MÂYX Cloud Gaming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
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
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  
  bool _isConnected = false;
  bool _isLoading = false;
  bool _isFullScreen = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _keyboardFocusNode.dispose();
    _exitFullScreen();
    super.dispose();
  }

  // Bật chế độ Full Screen (Xoay ngang & Ẩn thanh trạng thái)
  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() => _isFullScreen = true);
  }

  // Tắt chế độ Full Screen (Trở lại màn hình dọc mặc định)
  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() => _isFullScreen = false);
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _sendControlData(Map<String, dynamic> data) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(jsonEncode(data)));
    }
  }

  Future<void> _connectToServer() async {
    setState(() => _isLoading = true);
    try {
      String inputIp = _ipController.text.trim();
      if (inputIp.isEmpty) {
        throw Exception("Vui lòng nhập IP Server!");
      }
      if (!inputIp.contains(':')) {
        inputIp = "$inputIp:8080";
      }

      final uri = Uri.parse(inputIp.startsWith('http') ? inputIp : 'http://$inputIp/offer');

      _peerConnection = await createPeerConnection({
        'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
      });

      RTCDataChannelInit init = RTCDataChannelInit()..ordered = false;
      _dataChannel = await _peerConnection!.createDataChannel('control', init);

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
            _isConnected = true;
            _isLoading = false;
          });
          _enterFullScreen(); // Tự động bật Fullscreen khi bắt đầu stream
          _keyboardFocusNode.requestFocus();
        }
      };

      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        RTCSessionDescription answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
      } else {
        throw Exception("Server từ chối kết nối (${response.statusCode})");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _disconnect() {
    _dataChannel?.close();
    _peerConnection?.close();
    _exitFullScreen();
    setState(() {
      _isConnected = false;
      _remoteRenderer.srcObject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isConnected 
          ? null 
          : AppBar(
              title: const Text('MÂYX Cloud Gaming Client'),
              centerTitle: true,
              backgroundColor: const Color(0xFF1E293B),
            ),
      body: _isConnected
          ? KeyboardListener(
              focusNode: _keyboardFocusNode,
              autofocus: true,
              onKeyEvent: (KeyEvent event) {
                final key = event.logicalKey.debugName ?? '';
                final isDown = event is KeyDownEvent;
                _sendControlData({
                  'type': 'keyboard',
                  'key': key,
                  'is_down': isDown,
                });
              },
              child: Listener(
                onPointerHover: (PointerHoverEvent event) {
                  _sendControlData({
                    'type': 'mouse_move',
                    'dx': event.delta.dx,
                    'dy': event.delta.dy,
                  });
                },
                onPointerDown: (PointerDownEvent event) {
                  _sendControlData({
                    'type': 'mouse_click',
                    'button': event.buttons,
                    'is_down': true,
                  });
                },
                onPointerUp: (PointerUpEvent event) {
                  _sendControlData({
                    'type': 'mouse_click',
                    'button': event.buttons,
                    'is_down': false,
                  });
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RTCVideoView(
                        _remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                    // Thanh nút chức năng góc trên bên phải
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Row(
                        children: [
                          // Nút Bật/Tắt Toàn Màn Hình
                          FloatingActionButton.small(
                            heroTag: "btn_fullscreen",
                            backgroundColor: Colors.black54,
                            onPressed: _toggleFullScreen,
                            child: Icon(
                              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Nút Ngắt kết nối
                          FloatingActionButton.small(
                            heroTag: "btn_disconnect",
                            backgroundColor: Colors.red.withOpacity(0.8),
                            onPressed: _disconnect,
                            child: const Icon(Icons.power_settings_new),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập IP Server (Ví dụ: 192.168.1.15)',
                      hintText: '192.168.1.15',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lan),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                          onPressed: _connectToServer,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('KẾT NỐI SERVER', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
    );
  }
}
