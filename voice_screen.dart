import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _voiceGuardEnabled = true;
  late AnimationController _waveController;
  late Animation<double> _waveAnim;

  final List<String> _triggerWords = [
    'Help me',
    'SOS',
    'Emergency',
    'Save me',
  ];

  final List<Map<String, String>> _voiceLogs = [
    {'time': '10:32 AM', 'keyword': 'Help me', 'status': 'Alert Sent'},
    {'time': 'Yesterday', 'keyword': 'SOS', 'status': 'Alert Sent'},
    {'time': '2 days ago', 'keyword': 'Emergency', 'status': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _waveAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

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
                'Voice Activation',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Speak a keyword to trigger an alert',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white60),
              ),

              const SizedBox(height: 32),

              // Mic button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isListening = !_isListening);
                },
                child: ScaleTransition(
                  scale: _isListening ? _waveAnim : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isListening
                            ? [
                                const Color(0xFF00E5FF),
                                const Color(0xFF00BCD4),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                      ),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00BCD4)
                                    .withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                _isListening ? 'Listening…' : 'Tap to Start Listening',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isListening ? const Color(0xFF00E5FF) : Colors.white60,
                ),
              ),

              const SizedBox(height: 28),

              // Voice Guard toggle
              _buildToggleCard(),

              const SizedBox(height: 22),

              // Trigger words
              _buildSection(
                title: 'Trigger Keywords',
                icon: Icons.key_rounded,
                child: Column(
                  children: _triggerWords.map((word) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.record_voice_over_outlined,
                                size: 15, color: AppTheme.accentGreen),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '"$word"',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.check_circle,
                              size: 16, color: AppTheme.accentGreen),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 22),

              // Voice logs
              _buildSection(
                title: 'Voice Alert Log',
                icon: Icons.history_rounded,
                child: Column(
                  children: _voiceLogs.asMap().entries.map((e) {
                    final log = e.value;
                    final isLast = e.key == _voiceLogs.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                log['time']!,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.white38),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '"${log['keyword']}"',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: log['status'] == 'Alert Sent'
                                      ? AppTheme.accentGreen
                                          .withValues(alpha: 0.2)
                                      : Colors.redAccent
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log['status']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: log['status'] == 'Alert Sent'
                                        ? AppTheme.accentGreen
                                        : Colors.redAccent,
                                  ),
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

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded,
              color: Color(0xFF00BCD4), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Guard',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Auto-alert on keyword detection',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          Switch(
            value: _voiceGuardEnabled,
            onChanged: (val) => setState(() => _voiceGuardEnabled = val),
            activeColor: const Color(0xFF00BCD4),
            activeTrackColor:
                const Color(0xFF00BCD4).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required Widget child}) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 18),
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
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
