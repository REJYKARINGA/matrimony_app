import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/navigation_provider.dart';
import '../services/message_service.dart';
import 'dart:convert';

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

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0, selectedIndex, navProvider),
              _buildNavItem(Icons.search, Icons.search, 'Search', 4, selectedIndex, navProvider),
              _buildCenterMatchButton(selectedIndex, navProvider),
              _buildNavItem(
                Icons.chat_bubble_outline,
                Icons.chat_bubble,
                'Chat',
                2,
                selectedIndex,
                navProvider,
                showBadge: _unreadMessageCount > 0,
              ),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3, selectedIndex, navProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  top: 0,
                  right: 15,
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
        ),
      ),
    );
  }

  Widget _buildCenterMatchButton(int selectedIndex, NavigationProvider navProvider) {
    bool isSelected = selectedIndex == 1;
    return GestureDetector(
      onTap: () => _onItemTapped(1, navProvider),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2D55).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isSelected ? Icons.favorite : Icons.favorite_border,
              color: const Color(0xFFFF2D55),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
