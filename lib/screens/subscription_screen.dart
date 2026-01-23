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
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                          ? Colors.white
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
                                _currentSubscription['plan']['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${DateTime.parse(_currentSubscription['end_date']).toString().split(' ')[0]}',
                            style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_currentSubscription['plan']['price']}',
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
                          ? Colors.white
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
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
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

    return Card(
      color: theme.brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                Text(
                  '₹${plan['price']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${plan['duration_days']} days',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Messages: ${plan['max_messages'] ?? 'Unlimited'}', theme),
            _buildFeatureItem('Contacts: ${plan['max_contacts'] ?? 'Unlimited'}', theme),
            _buildFeatureItem(plan['can_view_contact'] == 1 ? '✓ View contact details' : '✗ View contact details', theme),
            _buildFeatureItem(plan['priority_listing'] == 1 ? '✓ Priority listing' : '✗ Priority listing', theme),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _subscribe(plan['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Subscribe Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, ThemeData theme) {
    bool isEnabled = feature.startsWith('✓');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled
                ? (theme.brightness == Brightness.dark ? Colors.green[300] : Colors.green[700])
                : (theme.brightness == Brightness.dark ? Colors.red[300] : Colors.red[700]),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature.replaceFirst(RegExp(r'^[✗✓]\s*'), ''),
            style: TextStyle(
              color: isEnabled
                  ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87)
                  : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}