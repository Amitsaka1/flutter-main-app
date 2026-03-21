import 'package:flutter/material.dart';
import 'debug_panel.dart';

class GlobalDebugWidget extends StatefulWidget {
  const GlobalDebugWidget({super.key});

  @override
  State<GlobalDebugWidget> createState() => _GlobalDebugWidgetState();
}

class _GlobalDebugWidgetState extends State<GlobalDebugWidget> {

  bool showPanel = false;

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [

        // 🔥 FLOATING ICON
        Positioned(
          top: 50,
          right: 10,
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                showPanel = !showPanel;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings, color: Colors.white),
            ),
          ),
        ),

        // 🔥 DEBUG PANEL
        if (showPanel) const DebugPanel(),

      ],
    );

  }

}
