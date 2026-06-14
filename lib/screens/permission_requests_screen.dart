import '../utils/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import '../services/navigation_provider.dart';
import '../widgets/common_footer.dart';
import 'user_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PermissionRequestsScreen extends StatefulWidget {
  final int initialTab; // 0 = received, 1 = sent
  const PermissionRequestsScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<PermissionRequestsScreen> createState() => _PermissionRequestsScreenState();
}

class _PermissionRequestsScreenState extends State<PermissionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _incomingRequests = [];
  List<dynamic> _sentRequests = [];
  bool _isLoadingIncoming = true;
  bool _isLoadingSent = true;
  Set<int> _approvingIds = {};
  Set<int> _rejectingIds = {};

  static const Color primaryCyan = AppColors.deepEmerald;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadIncoming();
    _loadSent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIncoming() async {
    setState(() => _isLoadingIncoming = true);
    try {
      final response = await PaymentService.getIncomingPermissionRequests();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => _incomingRequests = data['requests']['data'] ?? []);
      }
    } catch (e) {
      print('Error loading incoming requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingIncoming = false);
    }
  }

  Future<void> _loadSent() async {
    setState(() => _isLoadingSent = true);
    try {
      final response = await PaymentService.getSentPermissionRequests();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => _sentRequests = data['requests']['data'] ?? []);
      }
    } catch (e) {
      print('Error loading sent requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSent = false);
    }
  }

  Future<void> _approve(int requestId) async {
    setState(() => _approvingIds.add(requestId));
    try {
      final response = await PaymentService.approvePermissionRequest(requestId);
      if (response.statusCode == 200) {
        _loadIncoming();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission approved'), backgroundColor: AppColors.primaryGreen, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      print('Error approving: $e');
    } finally {
      if (mounted) setState(() => _approvingIds.remove(requestId));
    }
  }

  Future<void> _reject(int requestId) async {
    setState(() => _rejectingIds.add(requestId));
    try {
      final response = await PaymentService.rejectPermissionRequest(requestId);
      if (response.statusCode == 200) {
        _loadIncoming();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission rejected'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      print('Error rejecting: $e');
    } finally {
      if (mounted) setState(() => _rejectingIds.remove(requestId));
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.parse(createdAt);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.midnightEmerald, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Permission Requests',
          style: TextStyle(color: AppColors.midnightEmerald, fontWeight: FontWeight.w500, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryCyan,
          labelColor: primaryCyan,
          unselectedLabelColor: AppColors.mutedText,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingTab(),
          _buildSentTab(),
        ],
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

  Widget _buildIncomingTab() {
    if (_isLoadingIncoming) {
      return const Center(child: CircularProgressIndicator(color: primaryCyan));
    }
    if (_incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 80, color: AppColors.midnightEmerald.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No incoming permission requests', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: primaryCyan,
      onRefresh: () async { await _loadIncoming(); },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingRequests.length,
        itemBuilder: (context, index) {
          final req = _incomingRequests[index];
          final sender = req['requester'] ?? {};
          final senderProfile = sender['user_profile'] ?? {};
          final status = req['status'] ?? 'pending';
          final requestId = req['id'];
          final isApproving = _approvingIds.contains(requestId);
          final isRejecting = _rejectingIds.contains(requestId);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.midnightEmerald,
                      backgroundImage: senderProfile['profile_picture'] != null
                          ? NetworkImage(ApiService.getImageUrl(senderProfile['profile_picture']))
                          : null,
                      child: senderProfile['profile_picture'] == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${senderProfile['first_name'] ?? ''} ${senderProfile['last_name'] ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.midnightEmerald),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'wants to unlock your contact',
                            style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(req['created_at']),
                            style: TextStyle(color: AppColors.mutedText.withOpacity(0.7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: isRejecting ? null : () => _reject(requestId),
                            icon: isRejecting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.close_rounded, size: 18),
                            label: Text(isRejecting ? 'Rejecting...' : 'Reject', style: const TextStyle(fontWeight: FontWeight.w500)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              side: BorderSide(color: Colors.red.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: isApproving ? null : () => _approve(requestId),
                            icon: isApproving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(isApproving ? 'Approving...' : 'Approve', style: const TextStyle(fontWeight: FontWeight.w500)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'approved') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 16),
                        SizedBox(width: 6),
                        Text('Approved', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
                ] else if (status == 'rejected') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text('Rejected', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_isLoadingSent) {
      return const Center(child: CircularProgressIndicator(color: primaryCyan));
    }
    if (_sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 80, color: AppColors.midnightEmerald.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No sent permission requests', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: primaryCyan,
      onRefresh: () async { await _loadSent(); },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final req = _sentRequests[index];
          final target = req['target_user'] ?? {};
          final targetProfile = target['user_profile'] ?? {};
          final status = req['status'] ?? 'pending';

          Color statusColor;
          IconData statusIcon;
          String statusText;
          switch (status) {
            case 'approved':
              statusColor = AppColors.primaryGreen;
              statusIcon = Icons.check_circle;
              statusText = 'Approved';
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusIcon = Icons.cancel_outlined;
              statusText = 'Rejected';
              break;
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.hourglass_empty;
              statusText = 'Pending';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.midnightEmerald,
                  backgroundImage: targetProfile['profile_picture'] != null
                      ? NetworkImage(ApiService.getImageUrl(targetProfile['profile_picture']))
                      : null,
                  child: targetProfile['profile_picture'] == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${targetProfile['first_name'] ?? ''} ${targetProfile['last_name'] ?? ''}'.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.midnightEmerald),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(req['created_at']),
                        style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
