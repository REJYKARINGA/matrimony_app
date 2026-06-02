import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─────────────────────────────────────────
//  Network status enum
// ─────────────────────────────────────────
enum _NetStatus { connected, connecting, disconnected }

// ─────────────────────────────────────────
//  NetworkOverlay – wraps entire app
// ─────────────────────────────────────────
class NetworkOverlay extends StatefulWidget {
  final Widget child;
  const NetworkOverlay({super.key, required this.child});

  @override
  State<NetworkOverlay> createState() => _NetworkOverlayState();
}

class _NetworkOverlayState extends State<NetworkOverlay>
    with SingleTickerProviderStateMixin {
  _NetStatus _status = _NetStatus.connected;
  Timer? _connectedTimer;
  late StreamSubscription<List<ConnectivityResult>> _sub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the wifi icon while connecting
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkInitial();
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _onChanged(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final hasNet = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);

    if (!hasNet) {
      // Lost connection
      _connectedTimer?.cancel();
      if (_status != _NetStatus.disconnected) {
        setState(() => _status = _NetStatus.disconnected);
      }
    } else if (_status == _NetStatus.disconnected) {
      // Was offline → now reconnecting
      setState(() => _status = _NetStatus.connecting);
      _connectedTimer?.cancel();
      _connectedTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _status = _NetStatus.connected);
      });
    } else {
      // Was always online (initial state)
      if (_status != _NetStatus.connected) {
        setState(() => _status = _NetStatus.connected);
      }
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _connectedTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── banner visibility ─────────────────
  bool get _showBanner => _status != _NetStatus.connected;

  // ── banner config per state ───────────
  _BannerConfig get _cfg {
    switch (_status) {
      case _NetStatus.disconnected:
        return _BannerConfig(
          gradient: [const Color(0xFFFF8C00), const Color(0xFFFF6000)],
          icon: Icons.wifi_off_rounded,
          title: 'No Internet',
          subtitle: 'Check your connection and retry.',
          showRetry: true,
          showSpinner: false,
        );
      case _NetStatus.connecting:
        return _BannerConfig(
          gradient: [const Color(0xFF00A87D), const Color(0xFF007A5C)],
          icon: Icons.wifi_rounded,
          title: 'Connecting…',
          subtitle: 'Restoring your connection.',
          showRetry: false,
          showSpinner: true,
        );
      case _NetStatus.connected:
        return _BannerConfig(
          gradient: [const Color(0xFF00A87D), const Color(0xFF007A5C)],
          icon: Icons.wifi_rounded,
          title: 'Connected',
          subtitle: 'You\'re back online!',
          showRetry: false,
          showSpinner: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // ── Animated banner ───────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          bottom: _showBanner ? 20 : -120,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _showBanner ? 1.0 : 0.0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _Banner(
                    cfg: _cfg,
                    pulseAnim: _pulseAnim,
                    onRetry: _checkInitial,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
//  Internal banner config data class
// ─────────────────────────────────────────
class _BannerConfig {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showRetry;
  final bool showSpinner;

  const _BannerConfig({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showRetry,
    required this.showSpinner,
  });
}

// ─────────────────────────────────────────
//  Banner widget
// ─────────────────────────────────────────
class _Banner extends StatelessWidget {
  final _BannerConfig cfg;
  final Animation<double> pulseAnim;
  final VoidCallback onRetry;

  const _Banner({
    required this.cfg,
    required this.pulseAnim,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      elevation: 10,
      shadowColor: cfg.gradient.first.withAlpha(100),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cfg.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cfg.gradient.first.withAlpha(80),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: cfg.showSpinner
                  ? FadeTransition(
                      opacity: pulseAnim,
                      child: Icon(cfg.icon, color: Colors.white, size: 22),
                    )
                  : Icon(cfg.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cfg.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cfg.subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Spinner or Retry button
            if (cfg.showSpinner)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (cfg.showRetry)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SKELETON PROFILE CARD  –  import and use this wherever you
//  load profile data and want a nice shimmer placeholder.
//
//  Usage:
//    isLoading ? SkeletonProfileCard() : ActualProfileCard(...)
// ═══════════════════════════════════════════════════════════════
class SkeletonProfileCard extends StatefulWidget {
  const SkeletonProfileCard({super.key});

  @override
  State<SkeletonProfileCard> createState() => _SkeletonProfileCardState();
}

class _SkeletonProfileCardState extends State<SkeletonProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmer, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => _buildCard(_anim.value),
    );
  }

  Widget _buildCard(double shimmerPos) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo area
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: _shimmerBox(
              width: double.infinity,
              height: 260,
              shimmerPos: shimmerPos,
              borderRadius: 0,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + age row
                Row(
                  children: [
                    _shimmerBox(
                        width: 140,
                        height: 20,
                        shimmerPos: shimmerPos,
                        borderRadius: 6),
                    const SizedBox(width: 8),
                    _shimmerBox(
                        width: 40,
                        height: 20,
                        shimmerPos: shimmerPos,
                        borderRadius: 6),
                  ],
                ),
                const SizedBox(height: 10),

                // Location row
                Row(
                  children: [
                    _shimmerBox(
                        width: 16,
                        height: 16,
                        shimmerPos: shimmerPos,
                        borderRadius: 8),
                    const SizedBox(width: 6),
                    _shimmerBox(
                        width: 120,
                        height: 14,
                        shimmerPos: shimmerPos,
                        borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 10),

                // Tags row
                Row(
                  children: [
                    _shimmerBox(
                        width: 70,
                        height: 28,
                        shimmerPos: shimmerPos,
                        borderRadius: 14),
                    const SizedBox(width: 8),
                    _shimmerBox(
                        width: 80,
                        height: 28,
                        shimmerPos: shimmerPos,
                        borderRadius: 14),
                    const SizedBox(width: 8),
                    _shimmerBox(
                        width: 60,
                        height: 28,
                        shimmerPos: shimmerPos,
                        borderRadius: 14),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _shimmerBox(
                        width: 52,
                        height: 52,
                        shimmerPos: shimmerPos,
                        borderRadius: 26),
                    _shimmerBox(
                        width: 68,
                        height: 68,
                        shimmerPos: shimmerPos,
                        borderRadius: 34),
                    _shimmerBox(
                        width: 52,
                        height: 52,
                        shimmerPos: shimmerPos,
                        borderRadius: 26),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double shimmerPos,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(shimmerPos - 1, 0),
          end: Alignment(shimmerPos + 1, 0),
          colors: const [
            Color(0xFFEEEEEE),
            Color(0xFFF8F8F8),
            Color(0xFFEEEEEE),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
