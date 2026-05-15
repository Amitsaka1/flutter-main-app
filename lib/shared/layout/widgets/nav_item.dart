import 'package:flutter/material.dart';

class NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? highlightColor;

  const NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {

    final Color color = active
        ? highlightColor ?? const Color(0xFF00F5A0)
        : Colors.white60;

    // ================= UI START =================

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          AnimatedContainer(
            duration:
                const Duration(milliseconds: 250),

            padding: const EdgeInsets.all(6),

            decoration: active
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withOpacity(0.5),
                        blurRadius: 14,
                      ),
                    ],
                  )
                : null,

            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    // ================= UI END =================
  }
}
