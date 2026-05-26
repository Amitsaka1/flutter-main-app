import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  VOICE SEARCH BAR
//  Path: lib/features/voice_world/presentation/widgets/voice_search_bar.dart
//  Group shortId se search — parent se query aata hai
// ─────────────────────────────────────────────────────────

class VoiceSearchBar extends StatefulWidget {
  final String         query;
  final ValueChanged<String> onChange;
  final VoidCallback   onClear;

  const VoiceSearchBar({
    super.key,
    required this.query,
    required this.onChange,
    required this.onClear,
  });

  @override
  State<VoiceSearchBar> createState() => _VoiceSearchBarState();
}

class _VoiceSearchBarState extends State<VoiceSearchBar> {

  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _border    = Color(0xFF1E1E2E);
  static const _textMuted = Color(0xFF55556A);

  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(VoiceSearchBar old) {
    super.didUpdateWidget(old);
    // Provider se clear hone pe field bhi clear karo
    if (widget.query.isEmpty && _ctrl.text.isNotEmpty) {
      _ctrl.clear();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.query.isNotEmpty
              ? _goldA.withOpacity(0.4)
              : _border,
          width: 1,
        ),
      ),
      child: Row(
        children: [

          const SizedBox(width: 12),

          Icon(
            Icons.search_rounded,
            size:  18,
            color: widget.query.isNotEmpty ? _goldA : _textMuted,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller:  _ctrl,
              onChanged:   widget.onChange,
              style: const TextStyle(
                color:    Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:  "Search by Group ID (e.g. A3X9)",
                hintStyle: TextStyle(
                  color:    _textMuted,
                  fontSize: 13,
                ),
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),

          // Clear button — query ho tabhi dikhe
          if (widget.query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                widget.onClear();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.close_rounded,
                  size:  16,
                  color: _textMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
