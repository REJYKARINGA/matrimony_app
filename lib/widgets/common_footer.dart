import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/navigation_provider.dart';
import '../services/message_service.dart';
import 'dart:convert';
import 'dart:ui';

class CommonFooter extends StatefulWidget {
  const CommonFooter({Key? key}) : super(key: key);

  @override
  State<CommonFooter> createState() => _CommonFooterState();
}

class _CommonFooterState extends State<CommonFooter> {
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadMessageCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final response = await MessageService.getUnreadCount();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _unreadMessageCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading unread message count in footer: $e');
    }
  }

  void _onItemTapped(int index, NavigationProvider navProvider) {
    navProvider.setSelectedIndex(index);
    // If we are not on the HomeScreen, navigate to it
    if (ModalRoute.of(context)?.settings.name != '/home') {
       Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final selectedIndex = navProvider.selectedIndex;

    // Define the sequence of indices as they appear in the Row
    final List<int> menuOrder = [0, 4, 1, 2, 3];
    final int itemPosition = menuOrder.indexOf(selectedIndex);
    
    // Calculate alignment: -1.0 (left) to 1.0 (right)
    final double alignmentX = (itemPosition * 2 / 4) - 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Blurred Background Layer
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStaticNavItem(Icons.home_outlined, 'Home', 0, selectedIndex, navProvider),
                      _buildStaticNavItem(Icons.search_rounded, 'Search', 4, selectedIndex, navProvider),
                      _buildStaticNavItem(Icons.favorite_border, 'Match', 1, selectedIndex, navProvider),
                      _buildStaticNavItem(
                        Icons.chat_bubble_outline,
                        'Chat',
                        2,
                        selectedIndex,
                        navProvider,
                        showBadge: _unreadMessageCount > 0,
                      ),
                      _buildStaticNavItem(Icons.person_outline, 'Profile', 3, selectedIndex, navProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Floating Indicator (Moved outside ClipRRect to avoid clipping)
        Positioned.fill(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                alignment: Alignment(alignmentX, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.2, // One fifth of the width
                  child: _buildFloatingIndicator(selectedIndex),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticNavItem(
    IconData icon,
    String label,
    int index,
    int selectedIndex,
    NavigationProvider navProvider, {
    bool showBadge = false,
  }) {
    bool isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index, navProvider),
        child: Container(
          color: Colors.transparent,
          child: Opacity(
            opacity: isSelected ? 0.0 : 1.0, // Hide when bubble is over it
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: Colors.grey.shade600, size: 24),
                    if (showBadge)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4B4B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIndicator(int selectedIndex) {
    IconData activeIcon;
    Color activeColor;
    
    switch (selectedIndex) {
      case 0: activeIcon = Icons.home; activeColor = const Color(0xFF00BCD4); break;
      case 4: activeIcon = Icons.search_rounded; activeColor = const Color(0xFF00BCD4); break;
      case 1: activeIcon = Icons.favorite; activeColor = const Color(0xFFFF2D55); break;
      case 2: activeIcon = Icons.chat_bubble; activeColor = const Color(0xFF00BCD4); break;
      case 3: activeIcon = Icons.person; activeColor = const Color(0xFF00BCD4); break;
      default: activeIcon = Icons.home; activeColor = const Color(0xFF00BCD4);
    }

    return Transform.translate(
      offset: const Offset(0, -14),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(activeIcon, color: activeColor, size: 28),
            if (selectedIndex == 2 && _unreadMessageCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


}
