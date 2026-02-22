import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() =>
      _PremiumScreenState();
}

class _PremiumScreenState
    extends State<PremiumScreen> {

  bool loading = false;
  String message = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {

    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(
            base64Url.normalize(token.split(".")[1]))),
      );

      phone = payload["phone"] ?? "";

      if (phone.isEmpty && mounted) {
        context.go("/login");
      }

    } catch (_) {
      if (mounted) context.go("/login");
    }
  }

  Future<void> _subscribe() async {

    if (phone.isEmpty) return;

    setState(() {
      loading = true;
      message = "";
    });

    try {

      final response =
          await ApiClient.post("/create-order", {
        "phone": phone,
      });

      if (response["success"] == true) {

        setState(() {
          message = "Payment successful ✅";
        });

        // Delay redirect same as your code
        Timer(const Duration(milliseconds: 1500), () {
          if (mounted) context.go("/dashboard");
        });

      } else {
        setState(() {
          message = "Payment failed";
        });
      }

    } catch (_) {
      setState(() {
        message = "Server error";
      });
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        height: double.infinity,
        alignment: Alignment.center,
        color: const Color(0xFFF5F5F5),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 25,
                color: Colors.black12,
              )
            ],
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              const Text(
                "Upgrade to Premium",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "₹5 / month",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      loading ? null : _subscribe,
                  style: ElevatedButton
                      .styleFrom(
                    backgroundColor:
                        Colors.black,
                    padding:
                        const EdgeInsets
                            .all(12),
                  ),
                  child: Text(
                    loading
                        ? "Processing..."
                        : "Subscribe Now",
                  ),
                ),
              ),

              if (message.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                          top: 15),
                  child: Text(message),
                )
            ],
          ),
        ),
      ),
    );
  }
}
