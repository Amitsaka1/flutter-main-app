import 'package:flutter/material.dart';

/// "Find" / "change" dono jagah se use hone wala popup -- lever (slider)
/// + fixed 5km steps ke -/+ buttons se radius select karte hain, ek
/// "Your Location" row (real GPS -> Profile me save) bhi hai, phir andar
/// ka "Find"/"Update" button dabate hi confirm hota hai.
///
/// Result: selected radius (double, km) -- null agar user ne cancel kiya.
/// Confirm button tabhi enable hota hai jab radius touch kiya ho AND
/// location set ho (pehli baar) -- doosri baar location optional hai.
Future<double?> showRadiusPickerDialog(
  BuildContext context, {
  double initialRadiusKm = 0,
  double maxRadiusKm = 20.0,
  required bool initialLocationEnabled,
  required Future<bool> Function() onRequestLocation,
  String confirmLabel = "Find",
}) {
  return showDialog<double>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => _RadiusPickerDialog(
      initialRadiusKm: initialRadiusKm,
      maxRadiusKm: maxRadiusKm,
      initialLocationEnabled: initialLocationEnabled,
      onRequestLocation: onRequestLocation,
      confirmLabel: confirmLabel,
    ),
  );
}

class _RadiusPickerDialog extends StatefulWidget {
  final double initialRadiusKm;
  final double maxRadiusKm;
  final bool initialLocationEnabled;
  final Future<bool> Function() onRequestLocation;
  final String confirmLabel;

  const _RadiusPickerDialog({
    required this.initialRadiusKm,
    required this.maxRadiusKm,
    required this.initialLocationEnabled,
    required this.onRequestLocation,
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

  static const _step = 5.0; // ✅ Fixed steps: 0 -> 5 -> 10 -> 15 -> 20

  late double _radiusKm;
  bool _radiusTouched = false;
  late bool _locationEnabled;
  bool _locationBusy = false;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm.clamp(0, widget.maxRadiusKm);
    _locationEnabled = widget.initialLocationEnabled;
  }

  bool get _canConfirm => _radiusTouched && _locationEnabled;

  void _step(double delta) {
    setState(() {
      _radiusKm = (_radiusKm + delta).clamp(0, widget.maxRadiusKm);
      _radiusTouched = true;
    });
  }

  Future<void> _handleLocationTap() async {
    if (_locationBusy) return;
    setState(() => _locationBusy = true);
    final ok = await widget.onRequestLocation();
    if (!mounted) return;
    setState(() {
      _locationBusy = false;
      if (ok) _locationEnabled = true;
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location nahi mil paayi, dobara try karo")),
      );
    }
  }

  String get _label {
    final rounded = _radiusKm.toStringAsFixed(0);
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

            // ── -/+ 5km buttons + lever/slider (fixed steps) ────
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _step(-_step),
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
                      min: 0,
                      max: widget.maxRadiusKm,
                      divisions: (widget.maxRadiusKm / _step).round(),
                      onChanged: (v) => setState(() {
                        _radiusKm = v;
                        _radiusTouched = true;
                      }),
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => _step(_step),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("0 km", style: TextStyle(color: _muted, fontSize: 11)),
                  Text(
                    "${widget.maxRadiusKm.toStringAsFixed(0)} km",
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Your Location row ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141420),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, size: 16, color: _goldA),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Your Location",
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: _locationBusy ? null : _handleLocationTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_goldA, _goldC]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _locationBusy
                            ? "…"
                            : (_locationEnabled ? "Change" : "Location"),
                        style: const TextStyle(
                          color: Color(0xFF0A0A0F),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

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
                    onTap: _canConfirm
                        ? () => Navigator.of(context).pop(_radiusKm)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _canConfirm
                            ? const LinearGradient(
                                colors: [_goldA, _goldC],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _canConfirm ? null : _border,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _canConfirm
                            ? [
                                BoxShadow(
                                  color: _goldA.withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          widget.confirmLabel,
                          style: TextStyle(
                            color: _canConfirm ? const Color(0xFF0A0A0F) : _muted,
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
