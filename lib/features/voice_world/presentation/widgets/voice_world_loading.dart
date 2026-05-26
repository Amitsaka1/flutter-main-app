import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE WORLD LOADING
//  Path: lib/features/voice_world/presentation/widgets/voice_world_loading.dart
// ─────────────────────────────────────────────────────────

class VoiceWorldLoading extends StatefulWidget {
  const VoiceWorldLoading({super.key});

  @override
  State<VoiceWorldLoading> createState() => _VoiceWorldLoadingState();
}

class _VoiceWorldLoadingState extends State<VoiceWorldLoading>
    with SingleTickerProviderStateMixin {

  static const _bg      = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131F);
  static const _border  = Color(0xFF1E1E2E);
  static const _goldA   = Color(0xFFD4A843);

  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width:  width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              _surface,
              _border,
              _surface,
            ],
            transform: GradientRotation(_shimmer.value),
          ),
        ),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 32, height: 32, radius: 8),
              _shimmerBox(width: 40, height: 16, radius: 4),
            ],
          ),
          const SizedBox(height: 10),
          _shimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          _shimmerBox(width: 80, height: 11),
          const Spacer(),
          _shimmerBox(width: 70, height: 20, radius: 10),
          const SizedBox(height: 10),
          _shimmerBox(width: double.infinity, height: 34, radius: 9),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: Column(
          children: [

            // Fake header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  _shimmerBox(width: 38, height: 38, radius: 19),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 120, height: 16),
                      const SizedBox(height: 5),
                      _shimmerBox(width: 80, height: 10),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Fake search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _shimmerBox(
                width: double.infinity,
                height: 46,
                radius: 12,
              ),
            ),

            const SizedBox(height: 18),

            // Skeleton grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing:  12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => _skeletonCard(),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
