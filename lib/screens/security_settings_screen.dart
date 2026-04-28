import '../utils/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/login_history_model.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  List<LoginHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiService.getLoginHistory();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _history = (data['history'] as List)
              .map((h) => LoginHistory.fromJson(h))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Login History'),
        backgroundColor: AppColors.midnightEmerald,
        foregroundColor: Colors.white70,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No login history found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Sessions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final session = _history[index];
                            return _buildSessionCard(session);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSessionCard(LoginHistory session) {
    final bool isMobile = session.userAgent?.contains('Mobile') ?? false;
    final bool isWeb = session.userAgent?.contains('Mozilla') ?? false && !isMobile;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.white70.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isWeb ? AppColors.primaryBlue : Colors.green[50]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isWeb ? Icons.laptop : Icons.phone_android,
            color: (isWeb ? AppColors.primaryBlue : Colors.green),
            size: 24,
          ),
        ),
        title: Text(
          session.ipAddress ?? 'Unknown IP',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM dd, yyyy • hh:mm a').format(session.loginAt)),
            if (session.location != null)
              Text('Near ${session.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: session.id == _history.first.id 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Current', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10)),
            )
          : null,
      ),
    );
  }
}













