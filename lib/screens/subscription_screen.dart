import '../../../../../../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> _plans = [];
  dynamic _currentSubscription;
  bool _isLoading = true;
  bool _loadingSubscription = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadingSubscription = true;
      _errorMessage = null;
    });

    try {
      // Load both plans and current subscription
      final results = await Future.wait([
        SubscriptionService.getPlans(),
        SubscriptionService.getMySubscription(),
      ]);

      if (results[0].statusCode == 200) {
        final data = json.decode(results[0].body);
        setState(() {
          _plans = data['plans'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load subscription plans';
          _isLoading = false;
        });
      }

      if (results[1].statusCode == 200) {
        final data = json.decode(results[1].body);
        setState(() {
          _currentSubscription = data['subscription'];
          _loadingSubscription = false;
        });
      } else {
        setState(() {
          _loadingSubscription = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _loadingSubscription = false;
      });
    }
  }

  Future<void> _subscribe(int planId) async {
    try {
      final response = await SubscriptionService.subscribe(planId);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentSubscription = data['subscription'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription successful!')),
        );
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to subscribe';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Premium Plans',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: AppColors.cardDark,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Subscription Section
                if (_loadingSubscription)
                  const Center(child: CircularProgressIndicator())
                else if (_currentSubscription != null) ...[
                  Text(
                    'Your Current Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? AppColors.cardDark
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currentSubscription['plan']?['name'] ?? 'Unknown Plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.dark
                                      ? AppColors.cardDark
                                      : Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Active',
                                  style: const TextStyle(color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_currentSubscription['end_date'] != null)
                            Text(
                              'Expires: ${DateTime.parse(_currentSubscription['end_date']).toString().split(' ')[0]}',
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            )
                          else
                            Text(
                              'No Expiry (Lifetime)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_currentSubscription['plan']?['price'] ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  Text(
                    'Your Current Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? AppColors.cardDark
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No active subscription',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Available Plans Section
                const Text(
                  'Available Plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.error, size: 64, color: theme.brightness == Brightness.dark
                            ? Colors.red[300]
                            : Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.cardDark
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: AppColors.cardDark,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_plans.isEmpty)
                  const Center(
                    child: Text('No subscription plans available'),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _plans.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return _buildPlanCard(plan);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    final theme = Theme.of(context);
    final String planName = plan['name'].toString().toLowerCase();
    
    Color accentColor;
    List<Color> gradientColors;
    
    if (planName.contains('platinum')) {
      accentColor = const Color(0xFFE5E4E2);
      gradientColors = [const Color(0xFF2C3E50), const Color(0xFF000000)];
    } else if (planName.contains('gold')) {
      accentColor = const Color(0xFFFFD700);
      gradientColors = [const Color(0xFFB8860B), const Color(0xFF8B4513)];
    } else if (planName.contains('silver')) {
      accentColor = const Color(0xFFC0C0C0);
      gradientColors = [const Color(0xFF708090), const Color(0xFF2F4F4F)];
    } else {
      accentColor = theme.colorScheme.primary;
      gradientColors = [theme.colorScheme.primary, theme.colorScheme.secondary];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.cardDark.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cardDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              'Lifetime Access',
                              style: TextStyle(color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '₹${plan['price'].toString().replaceAll('.00', '')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cardDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 20),
                  ... (plan['features'] as List).map((feature) => _buildFeatureItem(feature, theme, true)),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => _subscribe(plan['id']),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white70.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Upgrade to ${plan['name']}',
                          style: TextStyle(
                            color: gradientColors[0],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, ThemeData theme, [bool isDarkBackground = false]) {
    bool isEnabled = !feature.startsWith('✗');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isEnabled 
                ? (isDarkBackground ? AppColors.cardDark.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.1))
                : (isDarkBackground ? AppColors.cardDark.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled ? Icons.check : Icons.close,
              color: isEnabled
                  ? (isDarkBackground ? AppColors.cardDark : Colors.green[700])
                  : (isDarkBackground ? Colors.white54 : Colors.red[700]),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.replaceFirst(RegExp(r'^[✗✓]\s*'), ''),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
                color: isEnabled
                    ? (isDarkBackground ? AppColors.cardDark : Colors.black87)
                    : (isDarkBackground ? Colors.white60 : Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}















