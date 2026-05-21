import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/user_session.dart';
import '../../../core/socket/global_socket_manager.dart';

import '../data/room_api.dart';

import 'widgets/room_tile.dart';
import 'widgets/room_empty.dart';
import 'widgets/room_section_header.dart';
import 'widgets/create_room_dialog.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({
    super.key,
  });

  @override
  State<RoomListScreen> createState() =>
      _RoomListScreenState();
}

class _RoomListScreenState
    extends State<RoomListScreen> {

  bool _loading = true;

  List<dynamic> _myRooms = [];
  List<dynamic> _liveRooms = [];

  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();

    _loadRooms();
    _listenRoomUpdates();
  }

  // =========================
  // SOCKET
  // =========================

  void _listenRoomUpdates() {

    _socketSub =
        GlobalSocketManager
            .instance
            .messages
            .listen((event) {

      if (event["type"] ==
          "ROOM_REMOVED") {

        final roomId =
            event["roomId"];

        if (!mounted) return;

        setState(() {

          _myRooms.removeWhere(
            (room) =>
                room["id"] ==
                roomId,
          );

          _liveRooms.removeWhere(
            (room) =>
                room["id"] ==
                roomId,
          );
        });
      }
    });
  }

  // =========================
  // LOAD ROOMS
  // =========================

  Future<void> _loadRooms() async {

    try {

      final userId =
          UserSession.getUserId();

      final myRooms =
          await RoomApi.getRooms(
        userId: userId,
        type: "MY",
      );

      final liveRooms =
          await RoomApi.getRooms();

      if (!mounted) return;

      setState(() {
        _myRooms = myRooms;
        _liveRooms = liveRooms;
        _loading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // =========================
  // ENTER ROOM
  // =========================

  Future<void> _enterRoom(
    Map<String, dynamic> room,
  ) async {

    final userId =
        UserSession.getUserId();

    if (userId == null) return;

    final roomId = room["id"];

    try {

      if (room["status"] ==
          "INACTIVE") {

        await RoomApi.activateRoom(
          userId: userId,
          roomId: roomId,
        );
      }

      if (!mounted) return;

      context.push(
        "/room",
        extra: {
          "roomId": roomId,
        },
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll(
              "Exception: ",
              "",
            ),
          ),
        ),
      );
    }
  }

  // =========================
  // CREATE ROOM
  // =========================

  void _openCreateRoomDialog() {

    final nameController =
        TextEditingController();

    final descController =
        TextEditingController();

    showDialog(
      context: context,

      builder: (context) {

        return CreateRoomDialog(
          nameController:
              nameController,

          descController:
              descController,

          onStart: () async {

            final userId =
                UserSession.getUserId();

            if (userId == null) {
              return;
            }

            try {

              final roomId =
                  await RoomApi
                      .createRoom(
                userId: userId,
                name:
                    nameController.text
                        .trim(),
                description:
                    descController.text
                        .trim(),
              );

              await RoomApi.activateRoom(
                userId: userId,
                roomId: roomId,
              );

              if (!mounted) return;

              Navigator.pop(context);

              context.push(
                "/room",
                extra: {
                  "roomId": roomId,
                },
              );

            } catch (e) {

              if (!mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString()
                        .replaceAll(
                      "Exception: ",
                      "",
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // =========================
  // DISPOSE
  // =========================

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Rooms",
        ),

        actions: [

          IconButton(
            icon: const Icon(
              Icons.add,
            ),

            onPressed:
                _openCreateRoomDialog,
          ),
        ],
      ),

      body: _loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : RefreshIndicator(
              onRefresh: _loadRooms,

              child: ListView(
                children: [

                  // 🔥 MY ROOMS

                  if (_myRooms.isNotEmpty) ...[

                    const RoomSectionHeader(
                      title: "My Rooms",
                    ),

                    ..._myRooms.map(
                      (room) {

                        return RoomTile(
                          room: room,

                          onTap: () =>
                              _enterRoom(
                            room,
                          ),
                        );
                      },
                    ),
                  ],

                  // 🔥 LIVE ROOMS

                  if (_liveRooms.isNotEmpty) ...[

                    const RoomSectionHeader(
                      title:
                          "🔥 Live Rooms",
                    ),

                    ..._liveRooms.map(
                      (room) {

                        return RoomTile(
                          room: room,

                          onTap: () =>
                              _enterRoom(
                            room,
                          ),
                        );
                      },
                    ),
                  ],

                  if (_myRooms.isEmpty &&
                      _liveRooms.isEmpty)

                    const RoomEmpty(),
                ],
              ),
            ),
    );

    // ================= UI END =================
  }
}
