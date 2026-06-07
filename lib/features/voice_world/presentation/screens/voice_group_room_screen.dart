import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/voice_group_model.dart';
import '../../../../providers/voice_world_provider.dart';
import '../../../../core/session/user_session.dart';
import '../widgets/voice_seat_grid.dart';
import '../widgets/voice_listener_bar.dart';
import '../widgets/voice_room_actions.dart';
import '../widgets/voice_mic_button.dart';
import '../widgets/voice_member_sheet.dart';
import '../widgets/voice_reconnecting_banner.dart';
import '../widgets/voice_room_chat_sheet.dart';

class VoiceGroupRoomScreen extends ConsumerStatefulWidget {
  final VoiceGroupModel group;

  const VoiceGroupRoomScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<VoiceGroupRoomScreen> createState() =>
      _VoiceGroupRoomScreenState();
}

class _VoiceGroupRoomScreenState
    extends ConsumerState<VoiceGroupRoomScreen> {

  static const _bg        = Color(0xFF0A0A0F);
  static const _goldA     = Color(0xFFD4A843);
  static const _goldB     = Color(0xFFE8C86A);
  static const _surface   = Color(0xFF0E0E18);
  static const _textMuted = Color(0xFF55556A);

  // ✅ FIX #1: Step tracking — user ko pata chale kya ho raha hai
  //
  // Problem: Pehle sirf ek spinner tha — "Joining room..." text
  //          User sochta tha app hang hua — 2-4 second wait lagta tha
  //
  // Fix: 3 steps track karo — Access check → Joining → Audio connect
  //      Screen TURANT khulegi (Fix #2), banner mein step dikhega
  //
  String _connectingStep = "Checking access...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinRoom();
    });
  }

  Future<void> _joinRoom() async {

    // ✅ FIX #1: Step 1 — Ban check
    if (mounted) setState(() => _connectingStep = "Checking access...");

    // ✅ FIX #1: Step 2 — Joining
    // Thoda delay taaki UI update ho sake
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _connectingStep = "Joining room...");

    await ref
        .read(voiceRoomProvider.notifier)
        .joinGroup(widget.group);

    // ✅ FIX #1: Step 3 — LiveKit connecting
    if (mounted) setState(() => _connectingStep = "Connecting audio...");
  }

  // ✅ UNCHANGED
  Future<bool> _onWillPop() async {
    await _leaveRoom();
    return false;
  }

  // ✅ UNCHANGED
  Future<void> _leaveRoom() async {
    // FIX: await mat karo — turant screen close karo
    // Cleanup background mein hoga
    ref.read(voiceRoomProvider.notifier).leaveGroup(_groupId);
    if (mounted) Navigator.pop(context);
  }
  // ✅ UNCHANGED
  void _showMemberSheet(VoiceMemberModel member) {
    final state    = ref.read(voiceRoomProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);

    VoiceMemberSheet.show(
      context:      context,
      member:       member,
      isLocalMuted: state.isLocalMuted(member.userId),
      isBiMuted:    state.isBiMuted(member.userId),
      onLocalMute:  () => notifier.toggleLocalMute(member.userId),
      onBiMute:     () => notifier.toggleBiMute(member.userId),
      onGift:       () => _openGiftSheet(member),
      onReport:     () => _openReportSheet(member),
    );
  }

  // ✅ UNCHANGED
  void _openGiftSheet(VoiceMemberModel member) {}

  // ✅ UNCHANGED
  void _openReportSheet(VoiceMemberModel member) {
    _showReportDialog(member);
  }

  // ✅ UNCHANGED
  void _showReportDialog(VoiceMemberModel member) {
    final reasons = [
      ("abusive",       "Abusive language 🤬"),
      ("harassment",    "Harassment 😤"),
      ("spam",          "Spam / noise 📢"),
      ("inappropriate", "Inappropriate content 🔞"),
      ("hate",          "Hate speech 🚫"),
    ];

    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(
        member:  member,
        reasons: reasons,
        onReport: (reason) {
          ref.read(voiceRoomProvider.notifier).reportUser(
            reportedId: member.userId,
            groupId:    widget.group.id,
            reason:     reason,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:  Text("Report submitted"),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // ✅ UNCHANGED
  void _checkPromotion(VoiceRoomState state) {
    if (state.justPromoted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [Text("🎙️ You're now a Speaker!")],
            ),
            backgroundColor: _goldA.withOpacity(0.9),
            duration:        const Duration(seconds: 3),
          ),
        );
        ref.read(voiceRoomProvider.notifier).clearPromoted();
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final state    = ref.watch(voiceRoomProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);

    _checkPromotion(state);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Error — ✅ UNCHANGED ───────────────────────────
    if (state.joinStatus == VoiceJoinStatus.error) {
      return _JoinError(
        message: state.errorMessage ?? "Failed to join",
        onBack:  () => Navigator.pop(context),
        onRetry: () => _joinRoom(),
      );
    }

    // ✅ FIX #2: INSTANT ROOM OPEN — _JoiningLoader HATA DIYA
    //
    // Problem: Pehle ye tha:
    //   if (state.joinStatus == VoiceJoinStatus.joining) {
    //     return _JoiningLoader(group: widget.group); // ❌ Full screen block
    //   }
    //   Matlab: Room tab tak nahi dikhta jab tak JOIN COMPLETE na ho
    //   Ban check → Join API → LiveKit = 2-4 second black screen
    //
    // Fix: Room UI TURANT dikhao
    //      Joining status ko banner mein dikhao (upar se)
    //      User instantly room ke andar feel karta hai
    //      LiveKit connect hone tak banner dikhta hai — transparent UX
    //
    final bool isConnecting = state.joinStatus == VoiceJoinStatus.joining;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [

              // ✅ FIX #2: Connecting banner — joining ke time dikhao
              //
              // Pehle: Full screen spinner block karta tha
              // Ab: Sirf top pe ek banner — room visible rehta hai
              //
              if (isConnecting)
                _ConnectingBanner(step: _connectingStep) // ✅ FIXED

              // ✅ UNCHANGED: Reconnecting banner (already tha)
              else
                VoiceReconnectingBanner(
                  isVisible: state.isReconnecting,
                ),

              // ✅ UNCHANGED: Baaki poora UI same
              _RoomAppBar(
                group:        widget.group,
                onLeave:      _leaveRoom,
                speakerCount: state.speakerCount,
              ),

              const SizedBox(height: 10),

              VoiceSeatGrid(
                members:           state.members,
                activeSpeakers:    state.activeSpeakers,
                localMuted:        state.localMutedUsers,
                biMuted:           state.biMutedUsers,
                myUserId:          UserSession.userId,
                onMemberLongPress: _showMemberSheet,
              ),

              const Spacer(),

              VoiceListenerBar(
                listenerCount: state.listenerCount,
                listeners:     state.listeners,
                onTap: () => VoiceListenerSheet.show(
                  context:       context,
                  listeners:     state.listeners,
                  listenerCount: state.listenerCount,
                ),
              ),
              const SizedBox(height: 10),

              VoiceRoomActions(
                onChat: () {
                  showModalBottomSheet(
                    context:            context,
                    backgroundColor:    Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const VoiceRoomChatSheet(),
                  );
                },
                onGift:   () {},
                onReport: () {},
              ),

              const SizedBox(height: 14),

              VoiceMicButton(
                isSpeaker: state.isSpeaker,
                isMicOn:   state.isMicOn,

                // ✅ FIX #2: Joining ke time mic button disabled rakho
                // Pehle: isLoading: false — mic button active tha joining mein bhi
                // Ab: isLoading: isConnecting — turant press na ho sake
                isLoading: isConnecting, // ✅ FIXED

                onToggle: notifier.toggleMic,
                onLeave:  _leaveRoom,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ✅ FIX #2: CONNECTING BANNER — NEW WIDGET
//  Pehle: Full screen _JoiningLoader
//  Ab: Sirf yeh chhota sa banner upar se
// ─────────────────────────────────────────────────────────

class _ConnectingBanner extends StatelessWidget {
  final String step;

  static const _goldA   = Color(0xFFD4A843);
  static const _surface = Color(0xFF0E0E18);

  const _ConnectingBanner({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:   _surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width:  14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:       _goldA,
            ),
          ),
          const SizedBox(width: 10),
          // ✅ FIX #1: Step text — user ko pata chale kya ho raha hai
          Text(
            step,
            style: TextStyle(
              color:    _goldA,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ROOM APP BAR — ✅ UNCHANGED
// ─────────────────────────────────────────────────────────

class _RoomAppBar extends StatelessWidget {
  final VoiceGroupModel group;
  final VoidCallback    onLeave;
  final int             speakerCount;

  static const _goldA     = Color(0xFFD4A843);
  static const _textMuted = Color(0xFF55556A);
  static const _border    = Color(0xFF1E1E2E);

  const _RoomAppBar({
    required this.group,
    required this.onLeave,
    required this.speakerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await (context
                  .findAncestorStateOfType<_VoiceGroupRoomScreenState>()
                  ?._leaveRoom());
            },
            child: Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  _border.withOpacity(0.5),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size:  18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${group.emoji}  ${group.name}",
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "#${group.shortId}",
                  style: const TextStyle(
                    color:    _textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color:        _goldA.withOpacity(0.08),
              border: Border.all(
                color: _goldA.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              "🎙️ $speakerCount/16",
              style: TextStyle(
                color:      _goldA,
                fontSize:   11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  JOIN ERROR — ✅ UNCHANGED
// ─────────────────────────────────────────────────────────

class _JoinError extends StatelessWidget {
  final String       message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  static const _bg    = Color(0xFF0A0A0F);
  static const _goldA = Color(0xFFD4A843);

  const _JoinError({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("😔", style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                message == "PERMANENTLY_BANNED"
                    ? "Your account has been suspended"
                    : message == "TEMPORARILY_BANNED"
                        ? "You are temporarily banned"
                        : "Could not join room",
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.red, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [_goldA, Color(0xFFE8C86A)],
                    ),
                  ),
                  child: const Text(
                    "Try Again",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:      Color(0xFF0A0A0F),
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _goldA.withOpacity(0.15),
                    border: Border.all(color: _goldA.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Go Back",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:      _goldA,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  REPORT SHEET — ✅ UNCHANGED
// ─────────────────────────────────────────────────────────

class _ReportSheet extends StatelessWidget {
  final VoiceMemberModel       member;
  final List<(String, String)> reasons;
  final void Function(String)  onReport;

  static const _bg        = Color(0xFF0E0E18);
  static const _surface   = Color(0xFF13131F);
  static const _goldA     = Color(0xFFD4A843);
  static const _border    = Color(0xFF1E1E2E);
  static const _textPrime = Color(0xFFF0EDE8);
  static const _textMuted = Color(0xFF55556A);

  const _ReportSheet({
    required this.member,
    required this.reasons,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        _border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Report ${member.name ?? "User"}",
            style: const TextStyle(
              color:      _textPrime,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Select a reason",
            style: TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...reasons.map((r) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onReport(r.$1);
            },
            child: Container(
              margin:  const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:        _surface,
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        color:    _textPrime,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size:  16,
                    color: _textMuted,
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
