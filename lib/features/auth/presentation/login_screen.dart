import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _otpController =
      TextEditingController();

  String countryCode = "+91";
  bool loading = false;
  String message = "";
  String step = "phone";

  @override
  void initState() {
    super.initState();

    ApiClient.clearToken();

    // 🔥 Update Check (Router Safe)
    Future.delayed(const Duration(seconds: 1), () {
      _checkForUpdate();
    });
  }

  // ================= UPDATE SYSTEM =================

  Future<void> _checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await http.get(
        Uri.parse("https://momo-1etm.onrender.com/app/version"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final serverVersion = data["version"] ?? 0;
        final apkUrl = data["apkUrl"];

        if (serverVersion > currentBuild) {
          _showUpdateDialog(apkUrl);
        }
      }
    } catch (_) {}
  }

  void _showUpdateDialog(String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Update Available"),
        content: const Text(
            "A new version of the app is available. Please update."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ================= OTP SYSTEM =================

  Future<void> _sendOtp() async {

    final trimmed =
        _phoneController.text.replaceAll(" ", "");

    if (trimmed.length < 8) {
      setState(() => message =
          "Enter valid phone number");
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    try {

      final res =
          await ApiClient.post("/send-otp", {
        "phone": trimmed,
      });

      if (res["success"] == true) {
        setState(() => step = "otp");
      } else {
        setState(() => message =
            res["message"] ??
                "Failed to send OTP");
      }

    } catch (_) {
      setState(() =>
          message = "Server error");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _verifyOtp() async {

    final trimmed =
        _phoneController.text.replaceAll(" ", "");

    if (_otpController.text.trim().isEmpty) {
      setState(() => message = "Enter OTP");
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    try {

      final res =
          await ApiClient.post("/verify-otp", {
        "phone": trimmed,
        "otp": _otpController.text.trim()
      });

      if (res["success"] == true) {

        await ApiClient.saveToken(res["token"]);

        if (res["profileRequired"] == true) {
          if (mounted)
            context.go("/create-profile");
        } else {
          if (mounted)
            context.go("/dashboard");
        }

      } else {
        setState(() => message =
            res["message"] ??
                "Invalid OTP");
      }

    } catch (_) {
      setState(() =>
          message = "Verification failed");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF111827),
              Color(0xFF0b0f19),
              Color(0xFF070b14),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        const BoxDecoration(
                      borderRadius:
                          BorderRadius.all(
                              Radius.circular(10)),
                      gradient:
                          LinearGradient(
                        colors: [
                          Color(0xFFFF4D4F),
                          Color(0xFF8B5CF6),
                          Color(0xFF00D9F5),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "N",
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    "Naxorah",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold),
                  )
                ],
              ),

              const Divider(
                  color: Colors.white10),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 24),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      if (step == "phone") ...[
                        const Text(
                          "Login with Mobile Number",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your mobile number to continue.",
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.white54),
                        ),
                        const SizedBox(height: 20),

                        _buildPhoneInput(),

                        const SizedBox(height: 16),

                        _primaryButton(
                            loading
                                ? "Sending OTP..."
                                : "Send OTP",
                            _sendOtp),
                      ],

                      if (step == "otp") ...[
                        const Text(
                          "Enter OTP",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We sent a code to $countryCode ${_phoneController.text}",
                          style: const TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.white54),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller:
                              _otpController,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              _inputDecoration(
                                  "Enter OTP"),
                        ),

                        const SizedBox(height: 16),

                        _primaryButton(
                            loading
                                ? "Verifying..."
                                : "Verify OTP",
                            _verifyOtp),
                      ],

                      if (message.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  top: 12),
                          child: Text(
                            message,
                            style:
                                const TextStyle(
                                    color:
                                        Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(
                    bottom: 10),
                child: Text(
                  "By continuing, you agree to the Terms of Service & Privacy Policy.",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.white54),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white24),
        color: Colors.black26,
      ),
      child: Row(
        children: [
          Text(countryCode),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller:
                  _phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                border: InputBorder.none,
                hintText:
                    "Enter mobile number",
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _primaryButton(
      String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            loading ? null : onTap,
        style: ElevatedButton
            .styleFrom(
          padding:
              const EdgeInsets.all(14),
          backgroundColor:
              const Color(0xFF2563EB),
        ),
        child: Text(text),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),
    );
  }
}
