import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PROFILE WALLET CARD  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class ProfileWalletCard extends StatefulWidget {
  final int wallet;

  const ProfileWalletCard({
    super.key,
    required this.wallet,
  });

  @override
  State<ProfileWalletCard> createState() => _ProfileWalletCardState();
}

class _ProfileWalletCardState extends State<ProfileWalletCard>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg        = Color(0xFF0A0A0F);
  static const _surface   = Color(0xFF0E0E18);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _goldC     = Color(0xFFB8892E);
  static const _border    = Color(0xFF2A2A3A);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  late AnimationController _ctrl;
  late Animation<double>   _glowPulse;
  late Animation<double>   _shimmer;
  late Animation<double>   _entrScale;
  late Animation<double>   _countAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Glow breathe
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // Shimmer sweep
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // Entrance
    _entrScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );

    // Count-up
    _countAnim = Tween<double>(
      begin: 0,
      end:   widget.wallet.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(ProfileWalletCard old) {
    super.didUpdateWidget(old);
    if (old.wallet != widget.wallet) {
      _ctrl
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Format balance ────────────────────────────
  String _format(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000)    return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    // ================= UI START =================

    return GestureDetector(
      onTapDown:   (_) => setState(() => _isPressed = true),
      onTapUp:     (_) => setState(() => _isPressed = false),
      onTapCancel: ()  => setState(() => _isPressed = false),

      child: AnimatedScale(
        scale:    _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve:    Curves.easeOut,

        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {

            return Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                // ── Gold gradient border shell ─────
                gradient: const LinearGradient(
                  colors: [_goldC, _goldA, _goldB, _goldA],
                  stops:  [0.0, 0.35, 0.65, 1.0],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),

                // ── Breathing glow ────────────────
                boxShadow: [
                  BoxShadow(
                    color: _goldA.withOpacity(
                      _glowPulse.value * 0.40,
                    ),
                    blurRadius:   20,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: _goldA.withOpacity(
                      _glowPulse.value * 0.15,
                    ),
                    blurRadius:   38,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.5),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // ── Dark inner surface ─────────
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF141410),
                            Color(0xFF1A1812),
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // ── Shimmer sweep ──────────────
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(
                          MediaQuery.of(context).size.width *
                              _shimmer.value * 0.35,
                          0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _goldA.withOpacity(0.08),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Content ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // Wallet icon in gold ring
                          Container(
                            width:  28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [_goldC, _goldA],
                                begin:  Alignment.topLeft,
                                end:    Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:       _goldA.withOpacity(0.45),
                                  blurRadius:  8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size:  14,
                              color: Color(0xFF0A0A0F),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Balance
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Label
                              Text(
                                "BALANCE",
                                style: TextStyle(
                                  color:         _goldA.withOpacity(0.55),
                                  fontSize:      8.5,
                                  fontWeight:    FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),

                              // Amount
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [_goldA, _goldB],
                                  begin:  Alignment.topLeft,
                                  end:    Alignment.bottomRight,
                                ).createShader(b),
                                child: Text(
                                  _format(_countAnim.value.toInt()),
                                  style: const TextStyle(
                                    color:         Colors.white,
                                    fontSize:      16,
                                    fontWeight:    FontWeight.w800,
                                    letterSpacing: 0.3,
                                    height:        1.1,
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
            );
          },
        ),
      ),
    );

    // ================= UI END =================
  }
}
