import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

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
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.x:8080");
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    setState(() => _isLoading = true);
    try {
      final serverUrl = _ipController.text.trim();
      final uri = Uri.parse(serverUrl.startsWith('http') ? serverUrl : 'http://$serverUrl/offer');

      // Tạo WebRTC Peer Connection
      _peerConnection = await createPeerConnection({
        'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
      });

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
            _isConnected = true;
            _isLoading = false;
          });
        }
      };

      // Thêm Transceiver nhận Video
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // Tạo Offer SDP
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Gửi Offer lên Server Python
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        RTCSessionDescription answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
      } else {
        throw Exception("Server trả về lỗi: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    }
  }

  void _disconnect() {
    _peerConnection?.close();
    setState(() {
      _isConnected = false;
      _remoteRenderer.srcObject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MÂYX Cloud Gaming Client'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _isConnected
          ? Stack(
              children: [
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.red,
                    onPressed: _disconnect,
                    child: const Icon(Icons.close),
                  ),
                )
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ IP Server (Ví dụ: 192.168.1.50:8080)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
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
                          label: const Text('KẾT NỐI SERVER'),
                        ),
                ],
              ),
            ),
    );
  }
}
