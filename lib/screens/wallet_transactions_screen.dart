import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'view_profile_screen.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  State<WalletTransactionsScreen> createState() => _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  double _walletBalance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  int? _currentTransactionId;
  late Razorpay _razorpay;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        PaymentService.getWalletBalance(),
        PaymentService.getTransactionHistory(),
      ]);

      if (results[0].statusCode == 200) {
        final data = json.decode(results[0].body);
        _walletBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
      }

      if (results[1].statusCode == 200) {
        final data = json.decode(results[1].body);
        _transactions = data['transactions']['data'] ?? [];
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Wallet & Transactions'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)], // Turquoise to Deep Blue
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    _buildQuickRecharge(),
                    _buildUsageFeeSummary(),
                    _buildTransactionHistory(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)], // Turquoise to Deep Blue
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_walletBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageFeeSummary() {
    final usageFees = _transactions.where((t) => t['type'] == 'usage_fee').toList();
    if (usageFees.isEmpty) return const SizedBox.shrink();
    final totalDeducted = usageFees.fold<double>(
      0,
      (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timelapse_rounded, color: Colors.orange.shade800, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-deducted Usage Fees',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${usageFees.length} deduction${usageFees.length > 1 ? 's' : ''} — ₹${totalDeducted.toStringAsFixed(0)} total deducted for passive usage',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRecharge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Recharge',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rechargeButton(199),
              _rechargeButton(499),
              _rechargeButton(999),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rechargeButton(double amount) {
    return InkWell(
      onTap: () => _handleRecharge(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)), // Turquoise border
        ),
        child: Text(
          '₹$amount',
          style: const TextStyle(
            color: Color(0xFF00BCD4), // Turquoise text
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    // Apply filter
    final filtered = _selectedFilter == 'all'
        ? _transactions
        : _transactions
            .where((t) => t['type'] == _selectedFilter)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Filter chips — only show if data exists for that type
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All', Icons.list_rounded),
                if (_transactions.any((t) => t['type'] == 'wallet_recharge')) ...[
                  const SizedBox(width: 8),
                  _filterChip('wallet_recharge', 'Recharges', Icons.add_circle_rounded),
                ],
                if (_transactions.any((t) => t['type'] == 'contact_unlock')) ...[
                  const SizedBox(width: 8),
                  _filterChip('contact_unlock', 'Unlocks', Icons.lock_open_rounded),
                ],
                if (_transactions.any((t) => t['type'] == 'usage_fee')) ...[
                  const SizedBox(width: 8),
                  _filterChip('usage_fee', 'Usage Fees', Icons.timelapse_rounded),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No transactions in this category'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final tx = filtered[index];
                final type = tx['type'] as String? ?? '';
                final isCredit = type == 'wallet_recharge';
                final isUsageFee = type == 'usage_fee';
                final isContactUnlock = type == 'contact_unlock';

                // Icon, color, and label per type
                IconData iconData;
                Color iconBg;
                Color iconColor;
                String typeLabel;

                if (isCredit) {
                  iconData = Icons.add_circle_rounded;
                  iconBg = Colors.green.withOpacity(0.12);
                  iconColor = Colors.green.shade700;
                  typeLabel = 'Wallet Recharge';
                } else if (isUsageFee) {
                  iconData = Icons.timelapse_rounded;
                  iconBg = Colors.orange.withOpacity(0.12);
                  iconColor = Colors.orange.shade800;
                  typeLabel = 'Usage Fee';
                } else if (isContactUnlock) {
                  iconData = Icons.lock_open_rounded;
                  iconBg = const Color(0xFF0D47A1).withOpacity(0.10);
                  iconColor = const Color(0xFF0D47A1);
                  typeLabel = 'Contact Unlock';
                } else {
                  iconData = Icons.remove_circle_rounded;
                  iconBg = Colors.red.withOpacity(0.10);
                  iconColor = Colors.red.shade700;
                  typeLabel = 'Deduction';
                }

                final description = tx['description'] as String? ?? typeLabel;
                final amount = tx['amount']?.toString() ?? '0';
                final status = tx['status']?.toString() ?? '';
                final createdAt = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();

                final unlockedUser = isContactUnlock
                    ? tx['unlocked_user'] as Map<String, dynamic>?
                    : null;
                final unlockedUserId = unlockedUser?['id'] as int?;

                final card = Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                typeLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // For contact_unlock — show person's name & matrimony_id
                              if (isContactUnlock && unlockedUser != null) ...[
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        [
                                          unlockedUser['first_name'],
                                          unlockedUser['last_name'],
                                        ].where((e) => e != null && e.toString().isNotEmpty).join(' '),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D47A1).withOpacity(0.09),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        unlockedUser['matrimony_id']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                              ] else ...[
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Amount + status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isCredit ? '+' : '-'}₹$amount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCredit
                                    ? Colors.green.shade700
                                    : isUsageFee
                                        ? Colors.orange.shade800
                                        : const Color(0xFF0D47A1),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: status == 'success'
                                    ? Colors.green.withOpacity(0.10)
                                    : Colors.orange.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: status == 'success'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

                // Contact unlock cards navigate to that person's profile
                if (isContactUnlock && unlockedUserId != null) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewProfileScreen(userId: unlockedUserId),
                      ),
                    ),
                    child: card,
                  );
                }

                return card;
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handleRecharge(double amount) async {
    try {
      final response = await PaymentService.createOrder(
        amount: amount,
        type: 'wallet_recharge',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _openRazorpay(data);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize payment')),
      );
    }
  }

  void _openRazorpay(Map<String, dynamic> orderData) {
    setState(() {
      _currentTransactionId = orderData['transaction_id'];
    });

    final options = {
      'key': orderData['key'],
      'amount': (orderData['amount'] * 100).toInt(),
      'currency': 'INR',
      'name': 'Matrimony App',
      'description': 'Wallet Recharge',
      'order_id': orderData['order_id'],
      'theme': {'color': '#00BCD4'},
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final razorpayOrderId = response.orderId;
      final razorpayPaymentId = response.paymentId;
      final razorpaySignature = response.signature;

      if (razorpayOrderId == null || razorpayPaymentId == null || razorpaySignature == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid payment response')),
        );
        return;
      }

      final verifyResponse = await PaymentService.verifyPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
        transactionId: _currentTransactionId ?? 0,
      );

      if (verifyResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recharge successful!')),
        );
        _loadData();
      }
    } catch (e) {
      print('Verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verification failed')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}