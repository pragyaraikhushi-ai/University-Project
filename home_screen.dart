import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'voice_screen.dart';
import 'map_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = 'Priya'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _safetyActive = true;
  bool _sosPressing = false;
  late AnimationController _sosPulseController;
  late Animation<double> _sosPulseAnim;

  // Time display
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sosPulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _sosPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sosPulseController.dispose();
    super.dispose();
  }

  // ── Bottom Nav pages ──────────────────────────────────────────────────────
  Widget _buildPage(int index) {
    switch (index) {
      case 1:
        return const VoiceScreen();
      case 2:
        return const MapScreen();
      case 3:
        return const ContactsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  // ── SOS long-press handler ────────────────────────────────────────────────
  void _onSosLongPress() {
    HapticFeedback.heavyImpact();
    setState(() => _sosPressing = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosAlertDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildPage(_selectedIndex),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.mic_rounded,
                label: 'Voice',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Map',
                selected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _NavItem(
                icon: Icons.contacts_rounded,
                label: 'Contacts',
                selected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: _selectedIndex == 4,
                onTap: () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main Home Content ─────────────────────────────────────────────────────
  Widget _buildHomeContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration:
          const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Top Row: greeting + notification bell ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // ── TITLE "Home" centred ──────────────────────────────
                  Text(
                    'Home',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // Notification bell
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── LINE 2: Welcome, <name> ───────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_greeting, ',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: 'Welcome ',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: widget.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' 👋',
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── LINE 3: Safety Status ─────────────────────────────────
              _buildSafetyStatusCard(),

              const SizedBox(height: 28),

              // ── SOS Button ────────────────────────────────────────────
              _buildSOSSection(),

              const SizedBox(height: 28),

              // ── Quick Action Cards ────────────────────────────────────
              _buildQuickActions(),

              const SizedBox(height: 20),

              // ── Recent Activity ───────────────────────────────────────
              _buildRecentActivity(),

              const SizedBox(height: 120), // padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  // ── Safety Status Card ────────────────────────────────────────────────────
  Widget _buildSafetyStatusCard() {
    return GestureDetector(
      onTap: () {
        setState(() => _safetyActive = !_safetyActive);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _safetyActive
                  ? 'Safety Status set to Active'
                  : 'Safety Status set to Inactive',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor:
                _safetyActive ? AppTheme.accentGreen : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _safetyActive
                ? AppTheme.accentGreen.withValues(alpha: 0.6)
                : Colors.redAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _safetyActive
                        ? AppTheme.accentGreen.withValues(alpha: 0.2)
                        : Colors.redAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _safetyActive
                        ? Icons.shield_rounded
                        : Icons.shield_outlined,
                    color: _safetyActive
                        ? AppTheme.accentGreen
                        : Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Status',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white60,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _safetyActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _safetyActive
                            ? AppTheme.accentGreen
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Tap to toggle hint
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _safetyActive
                    ? AppTheme.accentGreen.withValues(alpha: 0.2)
                    : Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _safetyActive
                          ? AppTheme.accentGreen
                          : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _safetyActive ? 'ON' : 'OFF',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _safetyActive
                          ? AppTheme.accentGreen
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SOS Section ───────────────────────────────────────────────────────────
  Widget _buildSOSSection() {
    return Column(
      children: [
        // Pulsing SOS button
        ScaleTransition(
          scale: _sosPulseAnim,
          child: GestureDetector(
            onLongPressStart: (_) {
              setState(() => _sosPressing = true);
              HapticFeedback.mediumImpact();
            },
            onLongPressEnd: (_) => _onSosLongPress(),
            onLongPressCancel: () => setState(() => _sosPressing = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _sosPressing
                      ? [
                          const Color(0xFFFF1744),
                          const Color(0xFFD50000),
                        ]
                      : [
                          const Color(0xFFFF5252),
                          const Color(0xFFFF1744),
                          const Color(0xFFD50000),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: _sosPressing ? 0.8 : 0.5),
                    blurRadius: _sosPressing ? 50 : 30,
                    spreadRadius: _sosPressing ? 12 : 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SOS',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── LINE 5: Press and hold hint ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_outlined,
                color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              'Press and Hold to send an alert',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Quick Action Cards ────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.mic_rounded,
        label: 'Voice\nActivation',
        color: const Color(0xFF00BCD4),
        onTap: () => setState(() => _selectedIndex = 1),
      ),
      _QuickAction(
        icon: Icons.map_rounded,
        label: 'Live\nLocation',
        color: const Color(0xFF4CAF50),
        onTap: () => setState(() => _selectedIndex = 2),
      ),
      _QuickAction(
        icon: Icons.contacts_rounded,
        label: 'Emergency\nContacts',
        color: const Color(0xFFFF9800),
        onTap: () => setState(() => _selectedIndex = 3),
      ),
      _QuickAction(
        icon: Icons.settings_rounded,
        label: 'Settings',
        color: const Color(0xFF9C27B0),
        onTap: () => setState(() => _selectedIndex = 4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((a) => _buildQuickActionCard(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: action.color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    final items = [
      _ActivityItem(
        icon: Icons.location_on_outlined,
        title: 'Location Shared',
        subtitle: 'Shared with 3 contacts',
        time: '2 min ago',
        color: AppTheme.accentGreen,
      ),
      _ActivityItem(
        icon: Icons.mic_none_rounded,
        title: 'Voice Guard Active',
        subtitle: 'Listening for keywords',
        time: '15 min ago',
        color: const Color(0xFF00BCD4),
      ),
      _ActivityItem(
        icon: Icons.shield_rounded,
        title: 'Safe Route Found',
        subtitle: 'Via MG Road — 1.2 km',
        time: '1 hr ago',
        color: AppTheme.primaryBlue,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12), width: 1),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon,
                              color: item.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                item.subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.time,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Bottom Nav Item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.accentGreen : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color:
                    selected ? AppTheme.accentGreen : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SOS Alert Dialog ──────────────────────────────────────────────────────────
class _SosAlertDialog extends StatefulWidget {
  @override
  State<_SosAlertDialog> createState() => _SosAlertDialogState();
}

class _SosAlertDialogState extends State<_SosAlertDialog> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(28),
      content: _sent ? _buildSentState() : _buildConfirmState(),
    );
  }

  Widget _buildConfirmState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_rounded,
              size: 40, color: Colors.redAccent),
        ),
        const SizedBox(height: 16),
        Text(
          '🚨 Send SOS Alert?',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your live location and an emergency message will be sent to all emergency contacts immediately.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppTheme.subtleGrey, height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.subtleGrey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(
                        color: AppTheme.subtleGrey,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() => _sent = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('SEND SOS',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSentState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.lightGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
              size: 42, color: AppTheme.accentGreen),
        ),
        const SizedBox(height: 16),
        Text('Alert Sent!',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Help is on the way. Your emergency contacts have been notified with your live location.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppTheme.subtleGrey, height: 1.5),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('OK, I\'m Safe Now',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  const _ActivityItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.time,
      required this.color});
}
