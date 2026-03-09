import 'package:flutter/material.dart';
import '../screens/wallet_transactions_screen.dart';

class WalletRechargePaywall extends StatelessWidget {
  final String? errorMessage;

  const WalletRechargePaywall({Key? key, this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rechargeOptions = [
      {'amount': 199, 'contacts': 4, 'popular': false},
      {'amount': 499, 'contacts': 10, 'popular': true},
      {'amount': 999, 'contacts': 20, 'popular': false},
      {'amount': 1999, 'contacts': 40, 'popular': false},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 10),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 64, color: Color(0xFF00BCD4)),
                    const SizedBox(height: 16),
                    const Text(
                      'Recharge Required',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                  ],
                ),
              );
            }
            final option = rechargeOptions[index - 1];
            return _buildPaywallPlanCard(context, option);
          },
          childCount: rechargeOptions.length + 1,
        ),
      ),
    );
  }

  Widget _buildPaywallPlanCard(BuildContext context, Map<String, dynamic> option) {
    int amount = option['amount'];
    int contacts = option['contacts'];
    bool isPopular = option['popular'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => WalletTransactionsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isPopular 
                ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
                : [const Color(0xFF00BCD4), const Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPopular ? const Color(0xFFFF9800) : const Color(0xFF00BCD4)).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.contacts_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                '$contacts Contacts',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wallet Recharge of ₹$amount',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isPopular) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MOST POPULAR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF57C00),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (isPopular)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            '₹$amount',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isPopular ? const Color(0xFFF57C00) : const Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
