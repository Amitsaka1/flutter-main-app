import 'package:flutter/material.dart';
import 'profile_card.dart';

// ─────────────────────────────────────────────
//  DASHBOARD GRID  —  Premium Dark VIP Edition
// ─────────────────────────────────────────────

class DashboardGrid extends StatefulWidget {
  final List<dynamic> profiles;
  final ScrollController scrollController;

  const DashboardGrid({
    super.key,
    required this.profiles,
    required this.scrollController,
  });

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid>
    with SingleTickerProviderStateMixin {

  // ── Palette ──────────────────────────────────
  static const _bg         = Color(0xFF0A0A0F);
  static const _goldA      = Color(0xFFD4A843);
  static const _textMuted  = Color(0xFF3A3A55);

  // ── Stagger controller ───────────────────────
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 400 + (widget.profiles.length.clamp(1, 6) * 80),
      ),
    )..forward();
  }

  @override
  void didUpdateWidget(DashboardGrid old) {
    super.didUpdateWidget(old);
    if (old.profiles.length != widget.profiles.length) {
      _staggerCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ── Per-item stagger interval ─────────────────
  Animation<double> _itemAnim(int index) {
    final total  = widget.profiles.length.clamp(1, 12);
    final start  = (index / total * 0.55).clamp(0.0, 0.75);
    final end    = (start + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  // ── Empty state ───────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon ring
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _textMuted.withOpacity(0.3), width: 1),
              color: const Color(0xFF0E0E18),
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 30,
              color: _textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "No profiles found",
            style: TextStyle(
              color: _textMuted.withOpacity(0.8),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters",
            style: TextStyle(
              color: _textMuted.withOpacity(0.5),
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===================== UI START =====================

    if (widget.profiles.isEmpty) return _emptyState();

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: widget.profiles.length,

      // ── Grid delegate ─────────────────────────
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),

      itemBuilder: (context, index) {
        final p    = widget.profiles[index];
        final anim = _itemAnim(index);

        return AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            final t = anim.value;

            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 28 * (1 - t)),
                child: Transform.scale(
                  scale: 0.92 + 0.08 * t,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            );
          },
          child: _GridItemShell(
            index: index,
            child: ProfileCard(profile: p),
          ),
        );
      },
    );

    // ===================== UI END =======================
  }
}

// ─────────────────────────────────────────────
//  Grid Item Shell — subtle depth + press state
// ─────────────────────────────────────────────

class _GridItemShell extends StatefulWidget {
  final int    index;
  final Widget child;

  const _GridItemShell({
    required this.index,
    required this.child,
  });

  @override
  State<_GridItemShell> createState() => _GridItemShellState();
}

class _GridItemShellState extends State<_GridItemShell>
    with SingleTickerProviderStateMixin {

  late AnimationController _pressCtrl;
  late Animation<double>   _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.955).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Alternate slight height offset for organic mosaic feel
    final bool lifted = widget.index % 3 == 1;

    return Padding(
      padding: EdgeInsets.only(top: lifted ? 0 : 10),
      child: GestureDetector(
        onTapDown:    (_) => _pressCtrl.forward(),
        onTapUp:      (_) => _pressCtrl.reverse(),
        onTapCancel:  ()  => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _pressAnim,
          builder: (_, child) => Transform.scale(
            scale: _pressAnim.value,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
