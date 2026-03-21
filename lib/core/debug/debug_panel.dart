import 'package:flutter/material.dart';
import 'app_debug.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {

  @override
  Widget build(BuildContext context) {

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 220,
        color: Colors.black.withOpacity(0.9),
        child: Column(
          children: [

            // 🔥 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "DEBUG PANEL",
                    style: TextStyle(color: Colors.green),
                  ),
                ),

                Row(
                  children: [

                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        setState(() {});
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        AppDebug.clear();
                        setState(() {});
                      },
                    ),

                  ],
                )

              ],
            ),

            // 🔥 LOGS
            Expanded(
              child: ListView.builder(
                itemCount: AppDebug.logs.length,
                itemBuilder: (context, index) {

                  final log = AppDebug.logs[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      log,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  );

                },
              ),
            ),

          ],
        ),
      ),
    );

  }

}
