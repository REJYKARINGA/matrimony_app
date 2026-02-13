import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ReverbService {
  static Echo? _echo;
  static PusherClient? _pusherClient;

  static void initialize(BuildContext context) {
    if (_echo != null) return;

    if (kIsWeb) {
      print('Reverb Service skipped on Web: pusher_client does not support Web platform.');
      return;
    }

    // Configuration for Reverb
    PusherOptions options = PusherOptions(
      host: 'localhost', 
      wsPort: 8080,
      encrypted: false,
    );

    _pusherClient = PusherClient(
      'fbenztk7q74qyavthtqk',
      options,
      autoConnect: true,
      enableLogging: true,
    );

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
