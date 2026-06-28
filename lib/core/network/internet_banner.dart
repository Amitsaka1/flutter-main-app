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
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          color: _isOffline
              ? const Color(0xFFD9534F)
              : const Color(0xFF3DAA63),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              _isOffline ? "No Internet Connection" : "Back Online",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
