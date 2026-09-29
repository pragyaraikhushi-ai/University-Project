import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _autoAlert = true;
  bool _nightMode = false;
  bool _biometric = true;
  bool _backgroundTracking = true;
  String _alertFrequency = 'Every 5 min';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Title
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Customise your safety preferences',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white60),
              ),

              const SizedBox(height: 24),

              // Profile card
              _buildProfileCard(),

              const SizedBox(height: 20),

              // Safety settings
              _buildSection(
                title: 'Safety',
                icon: Icons.shield_rounded,
                color: AppTheme.accentGreen,
                items: [
                  _SettingToggle(
                    icon: Icons.notifications_active_outlined,
                    label: 'Notifications',
                    subtitle: 'Receive safety alerts',
                    value: _notifications,
                    onChanged: (v) =>
                        setState(() => _notifications = v),
                    color: AppTheme.accentGreen,
                  ),
                  _SettingToggle(
                    icon: Icons.warning_amber_rounded,
                    label: 'Auto Alert',
                    subtitle: 'Alert on distress detection',
                    value: _autoAlert,
                    onChanged: (v) => setState(() => _autoAlert = v),
                    color: Colors.orangeAccent,
                  ),
                  _SettingToggle(
                    icon: Icons.location_on_rounded,
                    label: 'Background Tracking',
                    subtitle: 'Track location in background',
                    value: _backgroundTracking,
                    onChanged: (v) =>
                        setState(() => _backgroundTracking = v),
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // App settings
              _buildSection(
                title: 'App',
                icon: Icons.tune_rounded,
                color: AppTheme.primaryBlue,
                items: [
                  _SettingToggle(
                    icon: Icons.dark_mode_outlined,
                    label: 'Night Mode',
                    subtitle: 'Reduced brightness for night',
                    value: _nightMode,
                    onChanged: (v) => setState(() => _nightMode = v),
                    color: AppTheme.accentPurple,
                  ),
                  _SettingToggle(
                    icon: Icons.fingerprint_rounded,
                    label: 'Biometric Lock',
                    subtitle: 'Fingerprint/Face unlock',
                    value: _biometric,
                    onChanged: (v) => setState(() => _biometric = v),
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Alert frequency
              _buildFrequencySelector(),

              const SizedBox(height: 16),

              // Info links
              _buildSection(
                title: 'Support',
                icon: Icons.help_outline_rounded,
                color: Colors.white60,
                items: [
                  _SettingLink(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    color: AppTheme.primaryBlue,
                  ),
                  _SettingLink(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    color: AppTheme.primaryBlue,
                  ),
                  _SettingLink(
                    icon: Icons.help_center_outlined,
                    label: 'Help & FAQ',
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.redAccent, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 20),
                  label: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Women Safety App v1.0.0',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white30),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                AppTheme.accentGreen.withValues(alpha: 0.2),
            child: Text(
              'P',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priya Sharma',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'priya@example.com',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Safety Guard Active',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
              indent: 16,
              endIndent: 16),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast)
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }).toList(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    final options = ['Every 1 min', 'Every 5 min', 'Every 15 min'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.orangeAccent, size: 17),
              const SizedBox(width: 8),
              Text(
                'Alert Check Frequency',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((opt) {
              final sel = _alertFrequency == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _alertFrequency = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? Colors.orangeAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? Colors.orangeAccent.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.1),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color:
                            sel ? Colors.orangeAccent : Colors.white54,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded,
                size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Log Out?',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out? Your safety monitoring will be paused.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.subtleGrey,
                  height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.subtleGrey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
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
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (_) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Log Out',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
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

// ── Setting row widgets ───────────────────────────────────────────────────────
class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}

class _SettingLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SettingLink(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white38, size: 20),
        ],
      ),
    );
  }
}
