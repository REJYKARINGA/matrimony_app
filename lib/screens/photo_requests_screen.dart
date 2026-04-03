import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/photo_request_service.dart';
import '../services/api_service.dart';
import '../services/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'view_profile_screen.dart';
import '../widgets/common_footer.dart';

class PhotoRequestsScreen extends StatefulWidget {
  const PhotoRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PhotoRequestsScreen> createState() => _PhotoRequestsScreenState();
}

class _PhotoRequestsScreenState extends State<PhotoRequestsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  static const Color _cyan = Color(0xFF00BCD4);
  static const Color _green = Color(0xFF4CD9A6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await PhotoRequestService.getPendingRequests();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _requests = data['requests'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _error = 'Failed to load requests'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> _handleAccept(dynamic request) async {
    try {
      final response = await PhotoRequestService.acceptRequest(request['id']);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo request accepted! They can now view your photos.'),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _loadRequests();
      } else {
        _showError('Failed to accept request');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _handleReject(dynamic request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Request?'),
        content: const Text('Are you sure you want to decline this photo request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await PhotoRequestService.rejectRequest(request['id']);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request declined.'),
              backgroundColor: Colors.grey.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _loadRequests();
      } else {
        _showError('Failed to decline request');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  List<dynamic> get _pendingRequests =>
      _requests.where((r) => r['status'] == 'pending').toList();
  List<dynamic> get _acceptedRequests =>
      _requests.where((r) => r['status'] == 'accepted').toList();
  List<dynamic> get _rejectedRequests =>
      _requests.where((r) => r['status'] == 'rejected').toList();

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingRequests.length;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8F9FF),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          if (notification.direction == ScrollDirection.reverse) {
            navProvider.setFooterVisible(false);
          } else if (notification.direction == ScrollDirection.forward) {
            navProvider.setFooterVisible(true);
          }
          return true;
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 210.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 85),
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_cyan, _green],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Photo Requests',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            pendingCount > 0
                                ? '$pendingCount pending incoming request${pendingCount > 1 ? 's' : ''}'
                                : 'Manage photo access permissions',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: _cyan,
                    indicatorWeight: 3,
                    labelColor: _cyan,
                    unselectedLabelColor: Colors.grey.shade400,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pending'),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _cyan,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Accepted'),
                      const Tab(text: 'Declined'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadRequests,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRequestList(_pendingRequests, isPending: true),
                        _buildRequestList(_acceptedRequests, isAccepted: true),
                        _buildRequestList(_rejectedRequests),
                      ],
                    ),
        ),
      ),
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navProvider, child) => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: navProvider.isFooterVisible ? Offset.zero : const Offset(0, 2),
          child: const CommonFooter(),
        ),
      ),
    );
  }

  Widget _buildRequestList(List<dynamic> list, {bool isPending = false, bool isAccepted = false}) {
    if (list.isEmpty) {
      IconData icon;
      String title;
      String subtitle;

      if (isPending) {
        icon = Icons.inbox_rounded;
        title = 'No Pending Requests';
        subtitle = 'When someone requests to see your photos, they will appear here.';
      } else if (isAccepted) {
        icon = Icons.check_circle_outline_rounded;
        title = 'No Accepted Requests';
        subtitle = 'Profiles you\'ve allowed to view your photos appear here.';
      } else {
        icon = Icons.cancel_outlined;
        title = 'No Declined Requests';
        subtitle = 'Requests you\'ve declined will appear here.';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _cyan,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildRequestCard(list[index], isPending: isPending, isAccepted: isAccepted),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request, {bool isPending = false, bool isAccepted = false}) {
    final requester = request['requester'];
    final profile = requester?['user_profile'];
    final photos = requester?['profile_photos'] as List? ?? [];
    final String? profilePicture = profile?['profile_picture'];
    final String firstName = profile?['first_name'] ?? 'User';
    final String lastName = profile?['last_name'] ?? '';
    final String name = '$firstName $lastName'.trim();
    final String? city = profile?['city'];
    final String? religion = profile?['religion'];

    // Status badge
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (request['status']) {
      case 'accepted':
        statusColor = _green;
        statusLabel = 'Accepted';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        statusLabel = 'Declined';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = _cyan;
        statusLabel = 'Pending';
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Content
          InkWell(
            onTap: () {
              if (requester?['id'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ViewProfileScreen(userId: requester['id']),
                  ),
                );
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_cyan, _green]),
                        ),
                        child: profilePicture != null
                            ? ClipOval(
                                child: Image.network(
                                  ApiService.getImageUrl(profilePicture),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 30),
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(statusIcon, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (city != null || religion != null)
                          Text(
                            [city, religion].where((v) => v != null && v.isNotEmpty).join(' • '),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${photos.length} photo${photos.length != 1 ? 's' : ''} in gallery',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
          // Action Buttons (only for pending or rejected/declined)
          if (isPending || request['status'] == 'rejected') ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  if (request['status'] == 'pending') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReject(request),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: request['status'] == 'pending' ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(request),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        request['status'] == 'rejected' ? 'Give Access' : 'Allow Access',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isAccepted) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'This person can view your photos.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
