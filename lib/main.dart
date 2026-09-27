import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MayxCloudApp());
}

class MayxCloudApp extends StatelessWidget {
  const MayxCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayx Cloud Gaming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const RemoteScreen(),
    );
  }
}

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final TextEditingController _serverIpController = TextEditingController(text: '192.168.1.100:8080');
  
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  
  bool _isRendererReady = false;
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    try {
      await _remoteRenderer.initialize();
      if (mounted) {
        setState(() {
          _isRendererReady = true;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo RTCVideoRenderer: $e");
    }
  }

  Future<void> _connectToSignalingServer() async {
    if (!_isRendererReady) {
      _showSnackBar("Renderer chưa sẵn sàng, vui lòng đợi...");
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      Map<String, dynamic> mediaConstraints = {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      };

      _peerConnection = await createPeerConnection(configuration, mediaConstraints);

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          if (mounted) {
            setState(() {
              _remoteRenderer.srcObject = event.streams[0];
              _isConnected = true;
              _isConnecting = false;
            });
          }
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          _disconnect();
        }
      };

      RTCDataChannelInit dataChannelDict = RTCDataChannelInit();
      _dataChannel = await _peerConnection!.createDataChannel('controlChannel', dataChannelDict);

      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
      });
      await _peerConnection!.setLocalDescription(offer);

      final serverUrl = 'http://${_serverIpController.text.trim()}/offer';
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sdp': offer.sdp,
          'type': offer.type,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        RTCSessionDescription answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
      } else {
        throw Exception("Server từ chối kết nối (HTTP ${response.statusCode})");
      }
    } catch (e) {
      _disconnect();
      _showSnackBar("Kết nối thất bại: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _sendControlEvent(String type, Map<String, dynamic> data) {
    // FIX TỆT ĐỐI LỖI ENUM CỦA FLUTTER WEBRTC
    if (_dataChannel != null && 
        (_dataChannel!.state == RTCDataChannelState.RTCDataChannelStateOpen ||
         _dataChannel!.state.toString().contains('Open'))) {
      final payload = jsonEncode({'type': type, 'data': data});
      _dataChannel!.send(RTCDataChannelMessage(payload));
    }
  }

  void _disconnect() {
    _remoteRenderer.srcObject = null;
    _dataChannel?.close();
    _peerConnection?.close();
    _peerConnection = null;
    
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _remoteRenderer.srcObject = null;
    _remoteRenderer.dispose();
    _dataChannel?.close();
    _peerConnection?.close();
    _serverIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _isConnected && _isRendererReady
                ? Listener(
                    onPointerDown: (event) => _sendControlEvent('mousedown', {'button': event.buttons}),
                    onPointerUp: (event) => _sendControlEvent('mouseup', {'button': 0}),
                    onPointerMove: (event) => _sendControlEvent('mousemove', {
                      'dx': event.delta.dx,
                      'dy': event.delta.dy,
                    }),
                    child: RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                  )
                : Container(
                    color: Colors.black87,
                    child: Center(
                      child: Text(
                        _isConnecting ? "Đang thiết lập kết nối WebRTC..." : "Chưa kết nối Máy chủ",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
          ),

          if (!_isConnected)
            Positioned(
              top: 40,
              left: 40,
              right: 40,
              child: Card(
                color: Colors.black.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _serverIpController,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ Server (IP:Port)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: (_isConnecting || !_isRendererReady) ? null : _connectToSignalingServer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('KẾT NỐI'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isConnected)
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.red, size: 30),
                onPressed: _disconnect,
              ),
            ),
        ],
      ),
    );
  }
}
