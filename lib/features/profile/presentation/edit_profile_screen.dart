import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/location/location_service.dart';

import 'widgets/profile_form_text_field.dart';
import 'widgets/profile_form_dropdown.dart';
import 'widgets/profile_form_switch.dart';
import 'widgets/profile_save_button.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  // ── Form ─────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController ageController;

  String gender   = "";
  String roleType = "";
  bool   havePlace = false;
  bool   loading   = false;
  bool   locationEnabled  = false;
  bool   _locationLoading = false;

  // ── Entrance animation ───────────────────────
  late AnimationController _entranceCtrl;
  late Animation<double>   _fadeIn;
  late Animation<double>   _slideUp;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.profile["name"] ?? "",
    );
    usernameController = TextEditingController(
      text: widget.profile["username"] ?? "",
    );
    ageController = TextEditingController(
      text: widget.profile["age"]?.toString() ?? "",
    );

    gender    = widget.profile["gender"]   ?? "";
    roleType  = widget.profile["roleType"] ?? "";
    havePlace = widget.profile["havePlace"] ?? false;
    locationEnabled = widget.profile["locationEnabled"] ?? false;

    // Entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    nameController.dispose();
    usernameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // ===================== LOGIC START =====================

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final response = await ApiClient.put(
        "/profile/update",
        {
          "name":      nameController.text.trim(),
          "username":  usernameController.text.trim(),
          "age":       int.parse(ageController.text.trim()),
          "gender":    gender,
          "roleType":  roleType,
          "havePlace": havePlace,
        },
      );

      if (response["success"] == true) {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showErrorToast(e.toString());
    }

    if (mounted) setState(() => loading = false);
  }

  // 📍 Location toggle — ON karne se pehle consent dialog
  Future<void> _onLocationToggle(bool newValue) async {
    if (_locationLoading) return;

    if (!newValue) {
      // ⚠️ Abhi sirf UI state — backend se actual delete Fix #9 mein aayega
      setState(() => locationEnabled = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Share your location?",
          style: TextStyle(color: _textPrime),
        ),
        content: const Text(
          "Doosre users tumhari sirf approx distance dekh paayenge (jaise '2 km'). Exact location kabhi kisi ko nahi dikhayi jaati.",
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Allow",
              style: TextStyle(color: _goldA),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _locationLoading = true);

    final result = await LocationService.updateLocationOnLogin();

    if (!mounted) return;

    setState(() {
      _locationLoading = false;
      locationEnabled  = result == LocationUpdateResult.success;
    });

    if (result != LocationUpdateResult.success) {
      _showErrorToast(_locationMessageFor(result));
    }
  }

  String _locationMessageFor(LocationUpdateResult result) {
    switch (result) {
      case LocationUpdateResult.gpsOff:
        return "Location off hai — GPS on karke try karo.";
      case LocationUpdateResult.permissionPermanentlyDenied:
        return "Permission band hai — Settings mein jaake allow karo.";
      case LocationUpdateResult.permissionDenied:
        return "Permission allow nahi hui.";
      case LocationUpdateResult.locationUnavailable:
        return "Location nahi mil paayi — thodi der baad try karo.";
      default:
        return "Kuch gadbad hui — phir try karo.";
    }
  }

  // ===================== LOGIC END =======================
  
  // ── Error toast ───────────────────────────────
  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: _textPrime,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            style: TextStyle(
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

  // ── Section card wrapper ──────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Back button ───────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: _textPrime,
        ),
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

            // ── Top radial glow ───────────────
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _goldA.withOpacity(0.05),
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
                  child: Column(
                    children: [

                      // ── Header ──────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Row(
                          children: [

                            _buildBackButton(),

                            const SizedBox(width: 16),

                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [_goldA, _goldB],
                              ).createShader(b),
                              child: const Text(
                                "Edit Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Scrollable form ──────────────
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ── Section 1: Basic Info ────
                                _sectionLabel(
                                  "Basic Info",
                                  Icons.person_outline_rounded,
                                ),
                                _sectionCard(
                                  child: Column(
                                    children: [

                                      ProfileFormTextField(
                                        controller: nameController,
                                        label: "Name",
                                        validator: (v) => v == null || v.isEmpty
                                            ? "Enter name"
                                            : null,
                                      ),

                                      const SizedBox(height: 14),

                                      ProfileFormTextField(
                                        controller: usernameController,
                                        label: "Username",
                                        validator: (v) =>
                                            v == null || v.length < 3
                                                ? "Min 3 characters"
                                                : null,
                                      ),

                                      const SizedBox(height: 14),

                                      ProfileFormTextField(
                                        controller: ageController,
                                        label: "Age",
                                        keyboardType: TextInputType.number,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return "Enter age";
                                          }
                                          final age = int.tryParse(v);
                                          if (age == null ||
                                              age < 18 ||
                                              age > 100) {
                                            return "Invalid age (18–100)";
                                          }
                                          return null;
                                        },
                                      ),

                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Section 2: Preferences ───
                                _sectionLabel(
                                  "Preferences",
                                  Icons.tune_rounded,
                                ),
                                _sectionCard(
                                  child: Column(
                                    children: [

                                      ProfileFormDropdown<String>(
                                        value: gender.isEmpty ? null : gender,
                                        label: "Gender",
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
                                        onChanged: (v) =>
                                            setState(() => gender = v ?? ""),
                                      ),

                                      const SizedBox(height: 14),

                                      ProfileFormDropdown<String>(
                                        value: roleType.isEmpty
                                            ? null
                                            : roleType,
                                        label: "Role",
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
                                            value: "Versatile",
                                            child: Text("Versatile"),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => roleType = v ?? ""),
                                      ),

                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Section 3: Place ─────────
                                _sectionLabel(
                                  "Location",
                                  Icons.home_outlined,
                                ),
                                _sectionCard(
                                  child: ProfileFormSwitch(
                                    title: "Have Place",
                                    value: havePlace,
                                    onChanged: (v) =>
                                        setState(() => havePlace = v),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Section 4: Location Sharing ──
                                _sectionLabel(
                                  "Distance Visibility",
                                  Icons.location_on_outlined,
                                ),
                                _sectionCard(
                                  child: AbsorbPointer(
                                    absorbing: _locationLoading,
                                    child: Opacity(
                                      opacity: _locationLoading ? 0.5 : 1.0,
                                      child: ProfileFormSwitch(
                                        title: "Share My Location",
                                        value: locationEnabled,
                                        onChanged: _onLocationToggle,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // ── Save button ──────────────
                                ProfileSaveButton(
                                  loading: loading,
                                  onPressed: _updateProfile,
                                ),

                                const SizedBox(height: 20),

                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
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
