import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1a002b),
              Color(0xFF000000),
              Color(0xFF001f2f),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [

                // 🔥 APP TITLE + WALLET
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🔥 Naxorah",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00F5A0),
                            Color(0xFFFF00C8),
                          ],
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 18, color: Colors.black),
                          SizedBox(width: 6),
                          Text(
                            "0",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 30),

                // 🧑 PROFILE IMAGE
                Stack(
                  alignment: Alignment.center,
                  children: [

                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00F5A0),
                            Color(0xFFFF00C8),
                          ],
                        ),
                      ),
                    ),

                    const CircleAvatar(
                      radius: 65,
                      backgroundImage:
                          AssetImage("assets/profile_placeholder.png"),
                    ),

                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00F5A0),
                              Color(0xFFFF00C8),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 15),

                // 🏷 NAME
                const Text(
                  "Your Name",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "@username",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                // 👥 FOLLOW STATS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _StatBox(title: "Followed", value: "0"),
                    _StatBox(title: "Followers", value: "0"),
                  ],
                ),

                const SizedBox(height: 25),

                // ⭐ LEVEL BAR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2a003f),
                        Color(0xFF001f2f),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            "Level 1",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: 0,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.cyanAccent),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "0 / 100 XP",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ✏ EDIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: const BorderSide(
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 📦 EMPTY SECTION PLACEHOLDER
                const Text(
                  "Frames & Gifts will appear here",
                  style: TextStyle(color: Colors.white38),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔹 STAT BOX
class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
