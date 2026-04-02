import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'view_profile_screen.dart';

class WalletTransactionsScreen extends StatefulWidget {
  final String? initialMessage;
  const WalletTransactionsScreen({super.key, this.initialMessage});

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

    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHighlightDialog(widget.initialMessage!);
      });
    }
  }

  void _showHighlightDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Color(0xFF00BCD4)),
            SizedBox(width: 10),
            Text('Security Code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Share the 6-digit code with the sender to complete the transfer.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OKAY', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          ),
        ],
      ),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
              ElevatedButton.icon(
                onPressed: _showTransferDialog,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white30),
                  ),
                ),
              ),
            ],
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
                if (_transactions.any((t) => t['type'] == 'wallet_transfer')) ...[
                  const SizedBox(width: 8),
                  _filterChip('wallet_transfer', 'Transfers', Icons.swap_horiz_rounded),
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
                final isCredit = type == 'wallet_recharge' || (type == 'wallet_transfer' && tx['description'].toString().contains('Received'));
                final isUsageFee = type == 'usage_fee';
                final isContactUnlock = type == 'contact_unlock';
                final isWalletTransfer = type == 'wallet_transfer';

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
                } else if (isWalletTransfer) {
                  iconData = Icons.swap_horiz_rounded;
                  iconBg = Colors.purple.withOpacity(0.12);
                  iconColor = Colors.purple.shade700;
                  typeLabel = tx['description'].toString().contains('Sent') ? 'Transfer Sent' : 'Transfer Received';
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
                                        : isWalletTransfer
                                            ? Colors.purple.shade700
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

  void _showTransferDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _TransferDialog(),
    ).then((success) {
      if (success == true) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog();

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  int _step = 1; // 1: Search, 2: Amount, 3: OTP
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedUser;
  bool _isProcessing = false;
  String? _error;

  double get _amount => double.tryParse(_amountController.text) ?? 0.0;
  double get _fee => _amount * 0.10;
  double get _total => _amount + _fee;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _step == 1 ? 'Transfer Cash' : _step == 2 ? 'Enter Amount' : 'Verify Transfer',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],
            if (_step == 1) _buildSearchStep(),
            if (_step == 2) _buildAmountStep(),
            if (_step == 3) _buildOtpStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchStep() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by Matrimony ID or Phone',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (val) {
            if (val.length >= 3) _performSearch(val);
          },
        ),
        const SizedBox(height: 16),
        if (_isSearching)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_searchResults.isEmpty && _searchController.text.length >= 3)
          const Padding(padding: EdgeInsets.all(20), child: Text('No users found'))
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00BCD4).withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF00BCD4)),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(user['matrimony_id']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedUser = user;
                      _step = 2;
                      _error = null;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(_selectedUser!['name'][0])),
          title: Text(_selectedUser!['name']),
          subtitle: Text(_selectedUser!['matrimony_id']),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _billRow('Transfer Amount', '₹${_amount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _billRow('Platform Fee (10%)', '₹${_fee.toStringAsFixed(2)}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              _billRow('Total Deduction', '₹${_total.toStringAsFixed(2)}', isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _amount >= 500 && !_isProcessing ? _requestOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isProcessing 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Request Recipient OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(
                'Transfer ₹${_amount.toStringAsFixed(0)} to ${_selectedUser!['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Total deduction: ₹${_total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Enter the 6-digit security code provided by the recipient to confirm this transfer.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5, fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            if (val.length == 6) setState(() {});
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _otpController.text.length == 6 && !_isProcessing ? _completeTransfer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isProcessing 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Confirm Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 15 : 13)),
      ],
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final res = await PaymentService.searchUser(query);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _searchResults = data['users']);
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final res = await PaymentService.requestTransferOtp(
        recipientId: _selectedUser!['id'],
        amount: _amount,
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200) {
        setState(() => _step = 3);
        if (data['otp'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DEBUG: Recipient OTP is ${data['otp']}'), 
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 8)
            ),
          );
        }
      } else {
        setState(() => _error = data['error']);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _completeTransfer() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final res = await PaymentService.transferWallet(
        recipientId: _selectedUser!['id'],
        amount: _amount,
        otp: _otpController.text,
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer successful!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _error = data['error']);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}