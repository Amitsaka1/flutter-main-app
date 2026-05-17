import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────
//  PREMIUM SCREEN  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _surfaceHi = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _accent    = Color(0xFF6C63FF);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);
  static const _online    = Color(0xFF39E27A);
  static const _error     = Color(0xFFE05C5C);

  // ── State ─────────────────────────────────────
  bool   loading  = false;
  String message  = "";
  bool   isSuccess = false;
  String phone    = "";
  int    selectedTier = 0; // 0=Balanced, 1=Premium, 2=VIP
  String? loadingPackageId;

  Timer? _redirectTimer;

  // ── Controllers ──────────────────────────────
  late AnimationController _entranceCtrl;
  late AnimationController _tabCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _crownCtrl;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _tabSlide;
  late Animation<double> _glowPulse;
  late Animation<double> _crownFloat;
  late Animation<double> _particleAnim;

  // ── Tier data ─────────────────────────────────
  final List<_TierData> tiers = [
    _TierData(
      name:     "Balanced",
      label:    "BALANCED",
      tagline:  "Perfect for casual users",
      icon:     Icons.balance_rounded,
      colors:   [Color(0xFF5DADE2), Color(0xFF2E86C1)],
      packages: [
        _CoinPackage(id: "b1", coins: 50,   price: 5,  bonus: 0,   popular: false),
        _CoinPackage(id: "b2", coins: 120,  price: 10, bonus: 10,  popular: true),
        _CoinPackage(id: "b3", coins: 250,  price: 20, bonus: 20,  popular: false),
        _CoinPackage(id: "b4", coins: 500,  price: 35, bonus: 50,  popular: false),
      ],
    ),
    _TierData(
      name:    "Premium",
      label:   "PREMIUM",
      tagline: "Best value for power users",
      icon:    Icons.workspace_premium_rounded,
      colors:  [Color(0xFFD4A843), Color(0xFFB8892E)],
      packages: [
        _CoinPackage(id: "p1", coins: 300,  price: 25,  bonus: 30,  popular: false),
        _CoinPackage(id: "p2", coins: 650,  price: 50,  bonus: 80,  popular: true),
        _CoinPackage(id: "p3", coins: 1400, price: 99,  bonus: 200, popular: false),
        _CoinPackage(id: "p4", coins: 3000, price: 199, bonus: 500, popular: false),
      ],
    ),
    _TierData(
      name:    "VIP",
      label:   "VIP",
      tagline: "Exclusive perks & maximum coins",
      icon:    Icons.diamond_rounded,
      colors:  [Color(0xFF9B59B6), Color(0xFF6C63FF)],
      packages: [
        _CoinPackage(id: "v1", coins: 5000,  price: 299,  bonus: 1000, popular: false),
        _CoinPackage(id: "v2", coins: 12000, price: 599,  bonus: 3000, popular: true),
        _CoinPackage(id: "v3", coins: 25000, price: 999,  bonus: 8000, popular: false),
        _CoinPackage(id: "v4", coins: 60000, price: 1999, bonus: 20000,popular: false),
      ],
    ),
  ];

  // ── Particles ─────────────────────────────────
  static const _particles = [
    _Pt(dx: -140, dy: -180, size: 2.2, speed: 0.0),
    _Pt(dx:  130, dy: -150, size: 1.6, speed: 0.2),
    _Pt(dx: -120, dy:  100, size: 1.9, speed: 0.4),
    _Pt(dx:  150, dy:  120, size: 1.4, speed: 0.6),
    _Pt(dx: -160, dy:   30, size: 1.1, speed: 0.15),
    _Pt(dx:  100, dy:  -90, size: 2.0, speed: 0.75),
    _Pt(dx: -80,  dy: -220, size: 1.3, speed: 0.35),
    _Pt(dx:  170, dy:  -50, size: 1.7, speed: 0.55),
  ];

  @override
  void initState() {
    super.initState();

    // Entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideUp = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Tab switch
    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _tabSlide = CurvedAnimation(
      parent: _tabCtrl,
      curve: Curves.easeOutCubic,
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Crown float
    _crownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _crownFloat = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _crownCtrl, curve: Curves.easeInOut),
    );

    // Particles
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _particleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleCtrl, curve: Curves.linear),
    );

    _init();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _tabCtrl.dispose();
    _glowCtrl.dispose();
    _crownCtrl.dispose();
    _particleCtrl.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  // ===================== LOGIC START =====================

  Future<void> _init() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(
          base64Url.normalize(token.split(".")[1]),
        )),
      );

      phone = payload["phone"] ?? "";

      if (phone.isEmpty && mounted) {
        context.go("/login");
      }
    } catch (_) {
      if (mounted) context.go("/login");
    }
  }

  Future<void> _subscribe(_CoinPackage package) async {
    if (phone.isEmpty || loading) return;

    setState(() {
      loading          = true;
      loadingPackageId = package.id;
      message          = "";
      isSuccess        = false;
    });

    try {
      final response = await ApiClient.post("/create-order", {
        "phone":     phone,
        "packageId": package.id,
        "coins":     package.coins,
        "price":     package.price,
      });

      if (!mounted) return;

      if (response["success"] == true) {
        setState(() {
          message          = "Payment successful ✦ ${package.coins + package.bonus} coins added!";
          isSuccess        = true;
          loading          = false;
          loadingPackageId = null;
        });

        _redirectTimer = Timer(
          const Duration(milliseconds: 2000),
          () { if (mounted) context.go("/dashboard"); },
        );
      } else {
        setState(() {
          message          = response["message"] ?? "Payment failed. Please try again.";
          isSuccess        = false;
          loading          = false;
          loadingPackageId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          message          = "Server error. Please try again.";
          isSuccess        = false;
          loading          = false;
          loadingPackageId = null;
        });
      }
    }
  }

  // ===================== LOGIC END =======================

  void _switchTier(int index) {
    if (index == selectedTier) return;
    setState(() {
      selectedTier = index;
      message      = "";
    });
    _tabCtrl
      ..reset()
      ..forward();
  }

  // ── Current tier ─────────────────────────────
  _TierData get _currentTier => tiers[selectedTier];

  // ─────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [

          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color:        _surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size:  16,
                color: _textPrime,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_goldA, _goldB],
            ).createShader(b),
            child: const Text(
              "Premium",
              style: TextStyle(
                color:         Colors.white,
                fontSize:      22,
                fontWeight:    FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Hero crown section
  // ─────────────────────────────────────────────
  Widget _buildHero() {
    final colors = _currentTier.colors;

    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // Particles
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (_, __) {
              return SizedBox(
                width:  320,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: _particles.map((p) {
                    final t = (_particleAnim.value + p.speed) % 1.0;
                    final floatOffset = math.sin(t * 2 * math.pi) * 6;
                    return Positioned(
                      left: 160 + p.dx * 0.5,
                      top:  70  + p.dy * 0.3 + floatOffset,
                      child: Opacity(
                        opacity: (0.2 + math.sin(t * math.pi) * 0.4)
                            .clamp(0.0, 1.0),
                        child: Container(
                          width:  p.size,
                          height: p.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors[0],
                            boxShadow: [
                              BoxShadow(
                                color:      colors[0].withOpacity(0.6),
                                blurRadius: p.size * 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Crown icon
          AnimatedBuilder(
            animation: _crownFloat,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _crownFloat.value),
              child: AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, child) => Container(
                  width:  80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:       colors[0].withOpacity(_glowPulse.value * 0.5),
                        blurRadius:  30,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color:       colors[1].withOpacity(_glowPulse.value * 0.25),
                        blurRadius:  60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    _currentTier.icon,
                    size:  36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Tier tab selector
  // ─────────────────────────────────────────────
  Widget _buildTierTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color:        _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(tiers.length, (i) {
            final isActive = selectedTier == i;
            final colors   = tiers[i].colors;

            return Expanded(
              child: GestureDetector(
                onTap: () => _switchTier(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve:    Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isActive
                        ? LinearGradient(
                            colors: colors,
                            begin:  Alignment.topLeft,
                            end:    Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:      colors[0].withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tiers[i].icon,
                          size:  14,
                          color: isActive
                              ? Colors.white
                              : _textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tiers[i].name,
                          style: TextStyle(
                            color:      isActive ? Colors.white : _textMuted,
                            fontSize:   12,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Tier description
  // ─────────────────────────────────────────────
  Widget _buildTierDescription() {
    final tier   = _currentTier;
    final colors = tier.colors;

    return AnimatedBuilder(
      animation: _tabSlide,
      builder: (_, child) => Opacity(
        opacity: _tabSlide.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - _tabSlide.value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [

            // Tier badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical:    6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: colors,
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      colors[0].withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tier.icon, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    tier.label,
                    style: const TextStyle(
                      color:         Colors.white,
                      fontSize:      11,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Tagline
            Expanded(
              child: Text(
                tier.tagline,
                style: const TextStyle(
                  color:    _textMuted,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Coin package card
  // ─────────────────────────────────────────────
  Widget _buildCoinCard(_CoinPackage pkg) {
    final tier      = _currentTier;
    final colors    = tier.colors;
    final isLoading = loadingPackageId == pkg.id;
    final totalCoins = pkg.coins + pkg.bonus;

    return AnimatedBuilder(
      animation: _tabSlide,
      builder: (_, child) => Opacity(
        opacity: _tabSlide.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - _tabSlide.value)),
          child: child,
        ),
      ),
      child: _PressableCard(
        onTap: loading ? null : () => _subscribe(pkg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: pkg.popular
                ? LinearGradient(
                    colors: [
                      colors[0].withOpacity(0.3),
                      colors[1].withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),

              // Border
              gradient: LinearGradient(
                colors: pkg.popular
                    ? [
                        colors[0].withOpacity(0.7),
                        colors[1].withOpacity(0.3),
                        colors[0].withOpacity(0.5),
                      ]
                    : [
                        _border,
                        const Color(0xFF181824),
                        _border,
                      ],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),

              boxShadow: pkg.popular
                  ? [
                      BoxShadow(
                        color:       colors[0].withOpacity(0.2),
                        blurRadius:  20,
                        spreadRadius: -2,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color:       Colors.black.withOpacity(0.2),
                        blurRadius:  10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(1.2),

            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        _surfaceHi,
                borderRadius: BorderRadius.circular(17),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Popular badge
                  if (pkg.popular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical:   3,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: colors),
                      ),
                      child: const Text(
                        "BEST VALUE",
                        style: TextStyle(
                          color:         Colors.white,
                          fontSize:      9,
                          fontWeight:    FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                  // Coin icon + count
                  Row(
                    children: [

                      // Coin icon
                      Container(
                        width:  40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors,
                            begin:  Alignment.topLeft,
                            end:    Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:      colors[0].withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          size:  20,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Coin count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              colors: colors,
                            ).createShader(b),
                            child: Text(
                              _formatCoins(pkg.coins),
                              style: const TextStyle(
                                color:         Colors.white,
                                fontSize:      22,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: 0.3,
                                height:        1.0,
                              ),
                            ),
                          ),

                          if (pkg.bonus > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size:  11,
                                  color: _online,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "${_formatCoins(pkg.bonus)} bonus",
                                  style: TextStyle(
                                    color:    _online,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),

                        ],
                      ),

                    ],
                  ),

                  const SizedBox(height: 14),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _border,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Price + buy button
                  Row(
                    children: [

                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹${pkg.price}",
                            style: const TextStyle(
                              color:         _textPrime,
                              fontSize:      18,
                              fontWeight:    FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            "${_formatCoins(totalCoins)} coins total",
                            style: TextStyle(
                              color:    _textMuted,
                              fontSize: 10.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Buy button
                      GestureDetector(
                        onTap: loading ? null : () => _subscribe(pkg),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical:   10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: loading && !isLoading
                                ? null
                                : LinearGradient(
                                    colors: colors,
                                    begin:  Alignment.topLeft,
                                    end:    Alignment.bottomRight,
                                  ),
                            color: loading && !isLoading
                                ? _border
                                : null,
                            boxShadow: isLoading || (!loading)
                                ? [
                                    BoxShadow(
                                      color:      colors[0].withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width:  16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_rounded,
                                      size:  14,
                                      color: loading
                                          ? _textMuted
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Buy",
                                      style: TextStyle(
                                        color:      loading
                                            ? _textMuted
                                            : Colors.white,
                                        fontSize:   13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Format coins ──────────────────────────────
  String _formatCoins(int n) {
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K";
    return n.toString();
  }

  // ── Message pill ─────────────────────────────
  Widget _buildMessage() {
    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   12,
        ),
        decoration: BoxDecoration(
          color: isSuccess
              ? _online.withOpacity(0.08)
              : _error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSuccess
                ? _online.withOpacity(0.3)
                : _error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              size:  16,
              color: isSuccess ? _online : _error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color:    isSuccess ? _online : _error,
                  fontSize: 13,
                  fontWeight:   FontWeight.w500,
                  letterSpacing: 0.2,
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

            // ── Top radial glow ───────────────────
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _currentTier.colors[0].withOpacity(
                          _glowPulse.value * 0.10,
                        ),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────────
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

                      // Header
                      _buildHeader(),

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [

                              // Hero crown
                              _buildHero(),

                              // Tier tabs
                              _buildTierTabs(),

                              // Tier description
                              _buildTierDescription(),

                              const SizedBox(height: 16),

                              // Gold divider
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _goldA.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Coin packages grid
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics:    const NeverScrollableScrollPhysics(),
                                  itemCount:  _currentTier.packages.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:   2,
                                    mainAxisSpacing:  12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemBuilder: (_, i) =>
                                      _buildCoinCard(_currentTier.packages[i]),
                                ),
                              ),

                              // Message
                              _buildMessage(),

                              const SizedBox(height: 40),

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

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Pressable card wrapper
// ─────────────────────────────────────────────

class _PressableCard extends StatefulWidget {
  final Widget     child;
  final VoidCallback? onTap;

  const _PressableCard({required this.child, this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Data classes
// ─────────────────────────────
