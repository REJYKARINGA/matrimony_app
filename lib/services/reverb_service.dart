import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_config.dart';
import '../screens/notification_screen.dart';

class ReverbService {
  static Echo? _echo;
  static PusherClient? _pusherClient;

  static void initialize(BuildContext context, int? userId) {
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
        _showLiveSnackBar(context, message);
      }
    });

    // Listen to private user channel for scam alerts
    if (userId != null) {
      _echo!.private('App.Models.User.$userId').listen('.scam.alert', (data) {
        if (data != null && data['message'] != null) {
          _showLiveSnackBar(context, data['message'], isUrgent: true);
        }
      });
    }

    print('Reverb Service Initialized and Listening...');
  }

  static void _showLiveSnackBar(BuildContext context, String message, {bool isUrgent = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isUrgent ? Icons.gpp_bad_rounded : Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(isUrgent ? message : 'Live Notification: $message')),
          ],
        ),
        backgroundColor: isUrgent ? const Color(0xFFFF2D55) : const Color(0xFF5CB3FF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            );
          },
        ),
      ),
    );
  }
}
