import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please agree to the Terms & Conditions.',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);
      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 42, color: AppTheme.accentGreen),
            ),
            const SizedBox(height: 16),
            Text(
              'Account Created!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome, ${_nameController.text}! Your account has been created successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppTheme.subtleGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back to login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Go to Login',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress Indicator ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProgressIndicator(),
              ),

              const SizedBox(height: 12),

              // ── Scrollable Form ──────────────────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Subtitle
                          Text(
                            'Fill in your details to get started',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Form Card ──────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Section: Personal Information ───────
                                  _buildSectionHeader(
                                    icon: Icons.person_outline,
                                    title: 'Personal Information',
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(height: 18),

                                  // Full Name
                                  _buildLabel('Full Name *'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textDark),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icon(
                                          Icons.badge_outlined,
                                          color: AppTheme.primaryBlue),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Name is required';
                                      }
                                      if (val.trim().length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  // Age
                                  _buildLabel('Age *'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textDark),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your age',
                                      prefixIcon: Icon(
                                          Icons.cake_outlined,
                                          color: AppTheme.accentGreen),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Age is required';
                                      }
                                      final age = int.tryParse(val);
                                      if (age == null ||
                                          age < 10 ||
                                          age > 120) {
                                        return 'Enter a valid age (10–120)';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  // Gender
                                  _buildLabel('Gender *'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedGender,
                                    decoration: const InputDecoration(
                                      hintText: 'Select gender',
                                      prefixIcon: Icon(
                                          Icons.wc_outlined,
                                          color: AppTheme.accentPurple),
                                    ),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textDark),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    items: _genders
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => _selectedGender = val),
                                    validator: (val) => val == null
                                        ? 'Please select your gender'
                                        : null,
                                  ),

                                  const SizedBox(height: 28),

                                  // ── Section: Contact & Location ─────────
                                  _buildSectionHeader(
                                    icon: Icons.location_on_outlined,
                                    title: 'Contact & Location',
                                    color: AppTheme.accentPurple,
                                  ),
                                  const SizedBox(height: 18),

                                  // Address
                                  _buildLabel('Address *'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _addressController,
                                    maxLines: 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textDark),
                                    decoration: const InputDecoration(
                                      hintText:
                                          'House/Flat No., Street, City, State',
                                      alignLabelWithHint: true,
                                      prefixIcon: Padding(
                                        padding:
                                            EdgeInsets.only(bottom: 40),
                                        child: Icon(Icons.home_outlined,
                                            color: AppTheme.primaryBlue),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Address is required';
                                      }
                                      if (val.trim().length < 10) {
                                        return 'Please enter a complete address';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  // Contact Number
                                  _buildLabel('Contact Number *'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _contactController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textDark),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '+91 9876543210',
                                      prefixIcon: Icon(
                                          Icons.phone_outlined,
                                          color: AppTheme.accentGreen),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Contact number is required';
                                      }
                                      if (val.length < 10) {
                                        return 'Enter a valid contact number';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Terms & Conditions ──────────────────
                                  _buildTermsRow(),

                                  const SizedBox(height: 28),

                                  // ── Safety Tip Banner ───────────────────
                                  _buildSafetyTip(),

                                  const SizedBox(height: 24),

                                  // ── Register Button ─────────────────────
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentPurple,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        elevation: 6,
                                        shadowColor:
                                            AppTheme.accentPurple.withValues(alpha: 0.4),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.shield,
                                                    color: Colors.white,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Create My Account',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Already have account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Log In',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentGreen,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.25), thickness: 1.5),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreedToTerms ? AppTheme.accentGreen : Colors.transparent,
              border: Border.all(
                color: _agreedToTerms
                    ? AppTheme.accentGreen
                    : AppTheme.subtleGrey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.subtleGrey),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  const TextSpan(text: ' of Women Safety App.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.accentPurple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppTheme.accentGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '🔒 Your data is encrypted and kept private. Stay safe with 24/7 emergency support.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
