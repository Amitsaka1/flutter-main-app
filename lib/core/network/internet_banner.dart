import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';

// ─────────────────────────────────────────────────────────
//  INTERNET BANNER — global, app ke har screen pe top par dikhta hai
//  Path: lib/core/network/internet_banner.dart
// ─────────────────────────────────────────────────────────

class InternetBanner extends StatefulWidget {
  const InternetBanner({super.key});

  @override
  State<InternetBanner> createState() => _InternetBannerState();
}

class _InternetBannerState extends State<InternetBanner>
    with WidgetsBindingObserver {

  bool _isOffline       = false;
  bool _showReconnected = false;

  StreamSubscription<ConnectivityResult>? _sub;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Timer? _reconnectedTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkNow();

    _sub = Connectivity().onConnectivityChanged.listen((_) {
      // ✅ Debounce — rapid wifi/data switching pe baar-baar check na ho
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: 800),
        _checkNow,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNow();
    } else if (state == AppLifecycleState.paused) {
      // ✅ Background mein periodic retry band karo — battery/data bachao
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  Future<void> _checkNow() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInterface = connectivity != ConnectivityResult.none;

    // Interface hi off hai toh seedha offline maano, time bachao
    final reallyOnline =
        hasInterface ? await ApiClient.hasInternet() : false;

    if (!mounted) return;

    final wasOffline = _isOffline;

    setState(() => _isOffline = !reallyOnline);

    if (!reallyOnline) {
      // ✅ Abhi bhi offline — har 10 second retry karte raho
      // (kabhi-kabhi interface theek dikhta hai but backend reach nahi hota)
      _retryTimer ??= Timer.periodic(
        const Duration(seconds: 10),
        (_) => _checkNow(),
      );
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;

      if (wasOffline) {
        // ✅ Wapas online — "Back Online" thodi der dikhao fir hata do
        setState(() => _showReconnected = true);
        _reconnectedTimer?.cancel();
        _reconnectedTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showReconnected = false);
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _reconnectedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline && !_showReconnected) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _isOffline
                ? const LinearGradient(
                    colors: [Color(0xFF160707), Color(0xFF220D0D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF0E0C05), Color(0xFF1A1608)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            border: Border(
              bottom: BorderSide(
                color: _isOffline
                    ? const Color(0xFF7A2222)
                    : const Color(0xFFC9A84C).withOpacity(0.4),
                width: 0.8,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated indicator: pulsing dot (offline) / wifi icon (online) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: _isOffline
                    ? const _PulsingDot(
                        key: ValueKey('offline'),
                        color: Color(0xFFE05454),
                      )
                    : const Icon(
                        Icons.wifi_rounded,
                        key: ValueKey('online'),
                        color: Color(0xFFC9A84C),
                        size: 13,
                      ),
              ),
              const SizedBox(width: 7),
              // ── Animated text ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  _isOffline ? 'No Internet Connection' : 'Back Online',
                  key: ValueKey(_isOffline),
                  style: TextStyle(
                    color: _isOffline
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFFD4B866),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Pulsing dot — sirf offline state ke liye
//  Online pe static wifi icon zyada polished lagta hai
// ─────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({super.key, required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.55),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
