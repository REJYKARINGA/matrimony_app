import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_config.dart';

class ReverbService {
  static Echo? _echo;
  static PusherClient? _pusherClient;

  static void initialize(BuildContext context) {
    if (_echo != null) return;

    // Use current API base to determine secure status
    final bool isSecure = AppConfig.baseUrl.startsWith('https');

    // Configuration for Reverb
    PusherOptions options = PusherOptions(
      key: 'fbenztk7q74qyavthtqk',
      host: AppConfig.reverbHost,
      wsPort: 8080,
      wssPort: 8080,
      encrypted: isSecure,
      authOptions: PusherAuthOptions(
        '${AppConfig.baseUrl}/broadcasting/auth',
      ),
      cluster: 'mt1', // Default cluster
    );

    _pusherClient = PusherClient(
      options: options,
    );

    _pusherClient!.connect();

    _echo = Echo(
      broadcaster: EchoBroadcasterType.Pusher,
      client: _pusherClient,
    );

    // Listen to our test channel
    _echo!.channel('test-channel').listen('.test.event', (data) {
      if (data != null && data['message'] != null) {
        String message = data['message'];
        
        // Show a SnackBar when notification is received
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Live Notification: $message')),
              ],
            ),
            backgroundColor: const Color(0xFF5CB3FF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });

    print('Reverb Service Initialized and Listening...');
  }
}
