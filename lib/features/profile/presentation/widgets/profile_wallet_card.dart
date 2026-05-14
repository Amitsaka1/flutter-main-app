import 'package:flutter/material.dart';

class ProfileWalletCard extends StatelessWidget {
  final int wallet;

  const ProfileWalletCard({
    super.key,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C6FF),
            Color(0xFF7F00FF),
          ],
        ),
      ),
      child: Row(
        children: [

          const Icon(
            Icons.account_balance_wallet,
            size: 18,
            color: Colors.white,
          ),

          const SizedBox(width: 6),

          Text(
            wallet.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
