import 'package:flutter/material.dart';

/// "Find" / "change" dono jagah se use hone wala popup -- lever (slider)
/// + 1km ke -/+ buttons se radius select karte hain, phir andar ka
/// "Find"/"Update" button dabate hi confirm hota hai.
///
/// Result: selected radius (double, km) -- null agar user ne cancel kiya.
Future<double?> showRadiusPickerDialog(
  BuildContext context, {
  double initialRadiusKm = 5.0,
  double minRadiusKm = 0.5,
  double maxRadiusKm = 20.0,
  String confirmLabel = "Find",
}) {
  return showDialog<double>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => _RadiusPickerDialog(
      initialRadiusKm: initialRadiusKm,
      minRadiusKm: minRadiusKm,
      maxRadiusKm: maxRadiusKm,
      confirmLabel: confirmLabel,
    ),
  );
}

class _RadiusPickerDialog extends StatefulWidget {
  final double initialRadiusKm;
  final double minRadiusKm;
  final double maxRadiusKm;
  final String confirmLabel;

  const _RadiusPickerDialog({
    required this.initialRadiusKm,
    required this.minRadiusKm,
    required this.maxRadiusKm,
    required this.confirmLabel,
  });

  @override
  State<_RadiusPickerDialog> createState() => _RadiusPickerDialogState();
}

class _RadiusPickerDialogState extends State<_RadiusPickerDialog> {
  static const _bg      = Color(0xFF0E0E18);
  static const _goldA   = Color(0xFFD4A843);
  static const _goldB   = Color(0xFFE8C86A);
  static const _goldC   = Color(0xFFB8892E);
  static const _border  = Color(0xFF1E1E2E);
  static const _muted   = Color(0xFF55556A);

  late double _radiusKm;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm.clamp(
      widget.minRadiusKm,
      widget.maxRadiusKm,
    );
  }

  void _step(double delta) {
    setState(() {
      _radiusKm = (_radiusKm + delta).clamp(
        widget.minRadiusKm,
        widget.maxRadiusKm,
      );
    });
  }

  String get _label {
    // 1km ke neeche meters me dikhao (jaise "500 m"), warna km
    if (_radiusKm < 1) return "${(_radiusKm * 1000).round()} m";
    final rounded = _radiusKm == _radiusKm.roundToDouble()
        ? _radiusKm.toStringAsFixed(0)
        : _radiusKm.toStringAsFixed(1);
    return "$rounded km";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: _goldA.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  const LinearGradient(colors: [_goldA, _goldB]).createShader(b),
              child: const Text(
                "Set your radius",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Sirf isi radius ke andar wale log dikhenge",
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 22),

            // ── Big KM readout ──────────────────────────────────
            Text(
              _label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 18),

            // ── -/+ 1km buttons + lever/slider ──────────────────
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _step(-1),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: _goldA,
                      inactiveTrackColor: _border,
                      thumbColor: _goldB,
                      overlayColor: _goldA.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _radiusKm,
                      min: widget.minRadiusKm,
                      max: widget.maxRadiusKm,
                      onChanged: (v) => setState(() => _radiusKm = v),
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => _step(1),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.minRadiusKm < 1
                        ? "${(widget.minRadiusKm * 1000).round()} m"
                        : "${widget.minRadiusKm.toStringAsFixed(0)} km",
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  Text(
                    "${widget.maxRadiusKm.toStringAsFixed(0)} km",
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Cancel + Confirm ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(_radiusKm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_goldA, _goldC],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _goldA.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.confirmLabel,
                          style: const TextStyle(
                            color: Color(0xFF0A0A0F),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1E1E2E), width: 1),
        ),
        child: Icon(icon, color: const Color(0xFFD4A843), size: 18),
      ),
    );
  }
}
