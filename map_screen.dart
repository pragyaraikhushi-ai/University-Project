import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _locationSharing = true;
  String _selectedRoute = 'Safest';

  final List<Map<String, dynamic>> _routes = [
    {
      'label': 'Safest',
      'distance': '1.2 km',
      'time': '15 min',
      'icon': Icons.shield_rounded,
      'color': Color(0xFF4CAF50),
      'desc': 'Well-lit · CCTV monitored',
    },
    {
      'label': 'Fastest',
      'distance': '0.8 km',
      'time': '9 min',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFFFB300),
      'desc': 'Busy roads · Moderate safety',
    },
    {
      'label': 'Scenic',
      'distance': '1.6 km',
      'time': '20 min',
      'icon': Icons.park_rounded,
      'color': Color(0xFF00BCD4),
      'desc': 'Parks · Low traffic',
    },
  ];

  final List<Map<String, String>> _nearbyHelp = [
    {'name': 'City Police Station', 'dist': '0.4 km', 'icon': 'police'},
    {'name': 'Apollo Hospital', 'dist': '0.9 km', 'icon': 'hospital'},
    {'name': 'Women\'s Safety Centre', 'dist': '1.1 km', 'icon': 'safety'},
  ];

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
                'Live Location & Safe Route',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your location is always protected',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white60),
              ),

              const SizedBox(height: 24),

              // Map placeholder
              _buildMapPlaceholder(),

              const SizedBox(height: 20),

              // Location sharing toggle
              _buildLocationToggle(),

              const SizedBox(height: 20),

              // Route selector
              _buildRouteSelector(),

              const SizedBox(height: 20),

              // Nearby help
              _buildNearbyHelp(),

              const SizedBox(height: 20),

              // Share location button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Live location shared with emergency contacts!',
                            style: GoogleFonts.poppins()),
                        backgroundColor: AppTheme.accentGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.share_location_rounded,
                      color: Colors.white, size: 20),
                  label: Text(
                    'Share Live Location',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
            width: 1.5),
      ),
      child: Stack(
        children: [
          // Grid lines simulating map
          CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _MapGridPainter(),
          ),
          // Center pin
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '📍 Your Live Location',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Top-right badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gps_fixed_rounded,
                      size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle() {
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
          const Icon(Icons.location_on_rounded,
              color: Color(0xFF4CAF50), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Location Sharing',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text('Share with emergency contacts',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          Switch(
            value: _locationSharing,
            onChanged: (val) => setState(() => _locationSharing = val),
            activeColor: const Color(0xFF4CAF50),
            activeTrackColor:
                const Color(0xFF4CAF50).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Route',
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70),
        ),
        const SizedBox(height: 10),
        ...(_routes.map((route) {
          final selected = _selectedRoute == route['label'];
          final color = route['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedRoute = route['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.12),
                  width: selected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(route['icon'] as IconData,
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route['label']} Route',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? color : Colors.white,
                          ),
                        ),
                        Text(
                          route['desc'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        route['distance'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      Text(
                        route['time'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? color : Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildNearbyHelp() {
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
                const Icon(Icons.local_hospital_rounded,
                    color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Nearby Help',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
              indent: 16,
              endIndent: 16),
          ..._nearbyHelp.asMap().entries.map((e) {
            final item = e.value;
            final isLast = e.key == _nearbyHelp.length - 1;
            final iconData = item['icon'] == 'police'
                ? Icons.local_police_rounded
                : item['icon'] == 'hospital'
                    ? Icons.local_hospital_rounded
                    : Icons.security_rounded;
            final iconColor = item['icon'] == 'police'
                ? const Color(0xFF1A73E8)
                : item['icon'] == 'hospital'
                    ? Colors.redAccent
                    : AppTheme.accentGreen;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(iconData, color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['name']!,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        item['dist']!,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white54),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white38, size: 18),
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Map grid painter ──────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
