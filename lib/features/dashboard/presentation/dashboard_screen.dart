import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/controllers/nearby_controller.dart';
import '../../../core/location/nearby_service.dart';
import '../../../core/session/user_session.dart';
import '../../../shared/widgets/radius_picker_dialog.dart';

/// Dashboard = "Home" tab. Discovery-grid poori tarah hataya gaya hai --
/// ab sirf header (chat shortcut) + circular "Find" button + "Official
/// Group" tile hai (jab tak koi group na ho, tile hidden rehta hai).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF1E1E2E);
  static const _textMuted = Color(0xFF55556A);

  int unreadCount = 0;
  final _nearby = NearbyController.instance;
  bool _findBusy = false;

  late AnimationController _headerCtrl;
  late AnimationController _badgeCtrl;
  late Animation<double>   _headerFade;
  late Animation<double>   _headerSlide;
  late Animation<double>   _badgePulse;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _headerCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _badgePulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut),
    );

    _nearby.addListener(_onNearbyChanged);
    _nearby.loadFromDisk();

    _init();
  }

  void _onNearbyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      if (mounted) context.pushReplacement("/login");
      return;
    }

    _fetchUnread();
    ChatController.instance.loadChats();

    // NOTE: location ab yahan bilkul nahi mangi jati -- sirf "Find"
    // button dabane pe (agle step me wire hoga).

    ApiClient.get("/profile/me").then((profileRes) {
      if (!mounted) return;
      if (profileRes["success"] != true) {
        context.pushReplacement("/create-profile");
        return;
      }
      final data = profileRes["data"] as Map<String, dynamic>?;
      if (data != null) {
        UserSession.setProfile(
          name:      data["name"]      as String? ?? "",
          avatarUrl: data["avatarUrl"] as String?,
        );
        UserSession.locationEnabled = data["locationEnabled"] as bool? ?? false;
      }
    });
  }

  Future<void> _fetchUnread() async {
    try {
      final res = await ApiClient.get("/chat/recent");
      if (!mounted) return;
      if (res["success"] == true) {
        final data  = res["data"] as List;
        int   total = 0;
        for (var c in data) {
          total += (c["unreadCount"] ?? 0) as int;
        }
        setState(() => unreadCount = total);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nearby.removeListener(_onNearbyChanged);
    _headerCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  // ── Find button (circular) ──────────────────────────────────

  Future<void> _onFindTap() async {
    final radius = await showRadiusPickerDialog(
      context,
      initialRadiusKm: _nearby.hasGroup ? _nearby.radiusKm : 0,
      initialLocationEnabled: UserSession.locationEnabled,
      onRequestLocation: () async {
        final result = await _nearby.updateMyLocation();
        if (result == NearbyLocationResult.success) {
          UserSession.locationEnabled = true;
        }
        return result == NearbyLocationResult.success;
      },
      confirmLabel: "Find",
    );
    if (radius == null || !mounted) return;

    final wasNewGroup = !_nearby.hasGroup;
    setState(() => _findBusy = true);
    final result = await _nearby.findWithRadius(radius);
    if (!mounted) return;
    setState(() => _findBusy = false);

    if (result == NearbyLocationResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasNewGroup ? "Group created" : "Group updated successfully"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locationErrorMessage(result))),
      );
    }
  }

  String _locationErrorMessage(NearbyLocationResult result) {
    switch (result) {
      case NearbyLocationResult.locationNotSet:
        return "Pehle apni Location set karo";
      default:
        return "Kuch galat ho gaya, dobara try karo";
      default:
        return "Kuch galat ho gaya, dobara try karo";
    }
  }

  Widget _buildFindArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_nearby.hasGroup) ...[
          GestureDetector(
            onTap: () => context.push("/nearby-chat"),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_goldA, _goldC]),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFF0A0A0F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Official Group",
                          style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${_fmtKm(_nearby.radiusKm)} radius",
                          style: const TextStyle(color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
        GestureDetector(
          onTap: _findBusy ? null : _onFindTap,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_goldA, _goldC],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: _goldA.withOpacity(0.35), blurRadius: 24, spreadRadius: 2),
              ],
            ),
            child: _findBusy
                ? const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: Color(0xFF0A0A0F), strokeWidth: 3),
                  )
                : const Icon(Icons.explore_rounded, color: Color(0xFF0A0A0F), size: 34),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Find",
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ],
    );
  }

  String _fmtKm(double km) {
    if (km < 1) return "${(km * 1000).round()} m";
    return km == km.roundToDouble() ? "${km.toStringAsFixed(0)} km" : "${km.toStringAsFixed(1)} km";
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: AnimatedBuilder(
        animation: _headerSlide,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _headerSlide.value),
          child: child,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
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
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                size: 18,
                color: Color(0xFF0A0A0F),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [_goldA, _goldB],
                  ).createShader(b),
                  child: const Text(
                    "Nearby",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  "Find people around you",
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              // FIX: pehle "/chats" tha (galat, actual route "/chat" hai
              // -- button pehle kaam nahi kar raha tha).
              onTap: () => context.push("/chat"),
              child: AnimatedBuilder(
                animation: _badgePulse,
                builder: (_, child) => Transform.scale(
                  scale: unreadCount > 0 ? _badgePulse.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: unreadCount > 0
                          ? _goldA.withOpacity(0.5)
                          : _border,
                      width: 1,
                    ),
                    boxShadow: unreadCount > 0
                        ? [
                            BoxShadow(
                              color: _goldA.withOpacity(0.15),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        unreadCount > 0
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: unreadCount > 0 ? _goldA : _textMuted,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _goldA,
                              boxShadow: [
                                BoxShadow(
                                  color: _goldA.withOpacity(0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _buildHeader(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, _border, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(child: _buildFindArea()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
