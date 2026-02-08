import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import 'dart:js' as js;
import 'dart:html' as html;

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

  @override
  void initState() {
    super.initState();
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

  Widget _buildQuickRecharge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              _rechargeButton(100),
              _rechargeButton(500),
              _rechargeButton(1000),
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
          if (_transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No transactions yet'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isCredit = tx['type'] == 'wallet_recharge';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : const Color(0xFF0D47A1).withOpacity(0.1), // Deep blue for debit
                      child: Icon(
                        isCredit ? Icons.add : Icons.remove,
                        color: isCredit ? Colors.green : const Color(0xFF0D47A1), // Deep blue for debit
                      ),
                    ),
                    title: Text(tx['description'] ?? (isCredit ? 'Wallet Recharge' : 'Contact Unlock')),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(tx['created_at'])),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? '+' : '-'}₹${tx['amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.green : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          tx['status'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: tx['status'] == 'success' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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

    final script = html.ScriptElement()
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..async = true;
    html.document.head?.append(script);

    script.onLoad.listen((event) {
      final options = js.JsObject.jsify({
        'key': orderData['key'],
        'amount': (orderData['amount'] * 100).toInt(),
        'currency': 'INR',
        'name': 'Matrimony App',
        'description': 'Wallet Recharge',
        'order_id': orderData['order_id'],
        'handler': js.allowInterop((response) {
          _handleWebPaymentSuccess(response);
        }),
        'modal': {
          'ondismiss': js.allowInterop(() {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment cancelled')),
            );
          })
        },
        'theme': {'color': '#00BCD4'} // Turquoise theme for Razorpay
      });

      final razorpay = js.JsObject(js.context['Razorpay'], [options]);
      razorpay.callMethod('open');
    });
  }

  void _handleWebPaymentSuccess(dynamic response) async {
    try {
      final razorpayOrderId = js.JsObject.fromBrowserObject(response)['razorpay_order_id'];
      final razorpayPaymentId = js.JsObject.fromBrowserObject(response)['razorpay_payment_id'];
      final razorpaySignature = js.JsObject.fromBrowserObject(response)['razorpay_signature'];

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
}