import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';

import 'widgets/create_profile_text_field.dart';
import 'widgets/create_profile_dropdown.dart';
import 'widgets/create_profile_checkbox.dart';
import 'widgets/create_profile_button.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _accent    = Color(0xFF6C63FF);
  static const _error     = Color(0xFFE05C5C);

  // ── Form ─────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _ageController =
      TextEditingController();

  String? gender;
  String? roleType;
  bool    havePlace = false;
  bool    loading   = false;
  String  message   = "";

  // ── Entrance animation ───────────────────────
  late AnimationController _entranceCtrl;
  late Animation<double>   _fadeIn;
  late Animation<double>   _slideUp;
  late Animation<double>   _heroScale;
  late Animation<double>   _iconRotate;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _heroScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _iconRotate = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ===================== LOGIC START =====================

  Future<void> _submit() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.pushReplacement("/login");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      message = "";
    });

    try {
      final response = await ApiClient.post(
        "/profile/create",
        {
          "name":      _nameController.text.trim(),
          "gender":    gender,
          "roleType":  roleType,
          "havePlace": havePlace,
          "age":       int.parse(_ageController.text.trim()),
        },
      );

      if (response["success"] == true) {
        if (mounted) context.pushReplacement("/dashboard");
      } else {
        setState(() {
          message = response["message"] ?? "Profile creation failed";
        });
      }
    } catch (_) {
      setState(() => message = "Server error. Please try again.");
    }

    if (mounted) setState(() => loading = false);
  }

  // ===================== LOGIC END =======================

  // ── Section label ─────────────────────────────
  Widget _sectionLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _goldA.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _goldA.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Hero header ───────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [

        // Gold icon ring
        AnimatedBuilder(
          animation: _entranceCtrl,
          builder: (_, child) => Transform.scale(
            scale: _heroScale.value,
            child: Transform.rotate(
              angle: _iconRotate.value,
              child: child,
            ),
          ),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_goldA, _goldC],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _goldA.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: _accent.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 34,
              color: Color(0xFF0A0A0F),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Title
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_goldA, _goldB],
          ).createShader(b),
          child: const Text(
            "Create Profile",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        const Text(
          "Set up your identity to get started",
          style: TextStyle(
            color: _textMuted,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 6),

        // Gold dot divider
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              width: i == 1 ? 16 : 5,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == 1
                    ? _goldA
                    : _goldA.withOpacity(0.3),
              ),
            );
          }),
        ),

      ],
    );
  }

  // ── Error pill ────────────────────────────────
  Widget _buildError() {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: _error.withOpacity(0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _error.withOpacity(0.9),
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ===================== UI START =====================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [

            // ── Background top glow ───────────
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _goldA.withOpacity(0.07),
                      Colors.transparent,
                    ],
                    radius: 0.75,
                  ),
                ),
              ),
            ),

            // ── Bottom accent glow ────────────
            Positioned(
              bottom: -60,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _accent.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: AnimatedBuilder(
                  animation: _slideUp,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Hero ────────────────────────
                          Center(child: _buildHero()),

                          const SizedBox(height: 36),

                          // ── Section 1: Identity ──────────
                          _sectionLabel(
                            "Identity",
                            Icons.badge_outlined,
                          ),
                          _sectionCard(
                            child: Column(
                              children: [

                                CreateProfileTextField(
                                  controller: _nameController,
                                  label: "Full Name",
                                  validator: (v) =>
                                      v == null || v.isEmpty
                                          ? "Name required"
                                          : null,
                                ),

                                const SizedBox(height: 14),

                                CreateProfileTextField(
                                  controller: _ageController,
                                  label: "Age",
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Age required";
                                    }
                                    final age = int.tryParse(v);
                                    if (age == null || age < 18) {
                                      return "Must be 18 or older";
                                    }
                                    return null;
                                  },
                                ),

                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Section 2: About You ─────────
                          _sectionLabel(
                            "About You",
                            Icons.tune_rounded,
                          ),
                          _sectionCard(
                            child: Column(
                              children: [

                                CreateProfileDropdown<String>(
                                  value: gender,
                                  label: "Select Gender",
                                  items: const [
                                    DropdownMenuItem(
                                      value: "Male",
                                      child: Text("Male"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Female",
                                      child: Text("Female"),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => gender = val),
                                  validator: (val) =>
                                      val == null ? "Select gender" : null,
                                ),

                                const SizedBox(height: 14),

                                CreateProfileDropdown<String>(
                                  value: roleType,
                                  label: "Select Role",
                                  items: const [
                                    DropdownMenuItem(
                                      value: "Top",
                                      child: Text("Top"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Bottom",
                                      child: Text("Bottom"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Normal",
                                      child: Text("Normal"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Lesbian",
                                      child: Text("Lesbian"),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => roleType = val),
                                  validator: (val) =>
                                      val == null ? "Select role" : null,
                                ),

                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Section 3: Place ─────────────
                          _sectionLabel(
                            "Location",
                            Icons.home_outlined,
                          ),
                          _sectionCard(
                            child: CreateProfileCheckbox(
                              value: havePlace,
                              onChanged: (val) =>
                                  setState(() => havePlace = val ?? false),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Error message ────────────────
                          _buildError(),

                          if (message.isNotEmpty)
                            const SizedBox(height: 16),

                          // ── Create button ────────────────
                          SizedBox(
                            width: double.infinity,
                            child: CreateProfileButton(
                              loading: loading,
                              onPressed: _submit,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );

    // ===================== UI END =======================
  }
}
