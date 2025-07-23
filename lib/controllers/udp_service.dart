import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:udp/udp.dart';

class UdpService {
  // The port must match the one in the Arduino script
  static const int listenPort = 4210;

  UDP? _receiver;
  StreamSubscription? _subscription;
  final _controller = StreamController<String>.broadcast();

  // The UI will listen to this stream to get alerts
  Stream<String> get detectedElephantStream => _controller.stream;

  // Starts the listener
  Future<void> startListener() async {
    debugPrint("[UdpService] Starting listener on port $listenPort...");
    try {
      _receiver = await UDP.bind(Endpoint.any(port: Port(listenPort)));
      
      _subscription = _receiver?.asStream().listen((datagram) {
        if (datagram != null) {
          String message = utf8.decode(datagram.data);
          debugPrint("[UdpService] Received broadcast: $message");

          // Check if the message is the one we're looking for
          if (message.startsWith("ELEPHANT_NEARBY:")) {
            // Extract the device ID
            String deviceId = message.split(':')[1];
            _controller.add(deviceId);
          }
        }
      }, onError: (e) {
        debugPrint("[UdpService] Error receiving UDP packet: $e");
      });
      debugPrint("[UdpService] Listener started successfully.");
    } catch (e) {
      debugPrint("[UdpService] FAILED to start listener: $e");
    }
  }

  // Stops the listener and cleans up resources
  void dispose() {
    debugPrint("[UdpService] Disposing UDP service...");
    _subscription?.cancel();
    _receiver?.close();
    _controller.close();
  }
}
