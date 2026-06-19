import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../safety/screens/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const testFullName = 'Test User';
  static const testSouthAfricanFemaleId = '9001010000080';
  static const testPhoneNumber = '+27710000000';

  @visibleForTesting
  static bool isSouthAfricanFemaleId(String id) {
    return _LoginScreenState.isSouthAfricanFemaleId(id);
  }

  @visibleForTesting
  static bool isValidSouthAfricanId(String id) {
    return _LoginScreenState.isValidSouthAfricanId(id);
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _idError;
  late final AnimationController _animationController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @visibleForTesting
  static bool isSouthAfricanFemaleId(String id) {
    if (!isValidSouthAfricanId(id)) return false;
    return int.parse(id.substring(6, 10)) <= 4999;
  }

  @visibleForTesting
  static bool isValidSouthAfricanId(String id) {
    if (!RegExp(r'^\d{13}$').hasMatch(id)) return false;
    if (!_hasValidBirthDate(id.substring(0, 6))) return false;
    if (id[10] != '0' && id[10] != '1') return false;
    return _passesLuhn(id);
  }

  static bool _hasValidBirthDate(String yymmdd) {
    final year = int.parse(yymmdd.substring(0, 2));
    final month = int.parse(yymmdd.substring(2, 4));
    final day = int.parse(yymmdd.substring(4, 6));

    return _isRealDate(1900 + year, month, day) ||
        _isRealDate(2000 + year, month, day);
  }

  static bool _isRealDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }

  static bool _passesLuhn(String id) {
    var sum = 0;
    var shouldDouble = false;

    for (var i = id.length - 1; i >= 0; i--) {
      var digit = int.parse(id[i]);
      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      shouldDouble = !shouldDouble;
    }

    return sum % 10 == 0;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onIdChanged(String _) {
    setState(() => _idError = null);
  }

  void _fillTestProfile() {
    setState(() {
      _nameController.text = LoginScreen.testFullName;
      _idController.text = LoginScreen.testSouthAfricanFemaleId;
      _phoneController.text = LoginScreen.testPhoneNumber;
      _idError = null;
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _idError = null);
    if (!_formKey.currentState!.validate()) return;

    final id = _idController.text.trim();
    if (!isValidSouthAfricanId(id)) {
      setState(() {
        _idError = 'Please enter a valid 13-digit South African ID number.';
      });
      return;
    }

    if (!isSouthAfricanFemaleId(id)) {
      _showAccessRestrictedDialog();
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  void _showAccessRestrictedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFEC4899),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Access Restricted',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This platform is exclusively for women and girls. The ID number provided is not in the female ID sequence.\n\nIf you believe this is an error, please contact support.',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _idController.clear();
                setState(() {});
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEC4899),
              ),
              child: Text(
                'Understood',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10121B),
              AppColors.background,
              Color(0xFF0B1514),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFEC4899),
                                              Color(0xFF14B8A6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF14B8A6,
                                              ).withValues(alpha: 0.26),
                                              blurRadius: 22,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.white,
                                          size: 38,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'GBV Safe Hub',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'A safer space for women and girls',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF5EEAD4),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 36),
                                _NoticeBanner(),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _fillTestProfile,
                                    icon: const Icon(
                                      Icons.science_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Use test profile',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _buildLabel('Full Name'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  textCapitalization: TextCapitalization.words,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'e.g. Nomsa Dlamini',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length < 2) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('SA ID Number'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _idController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 13,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                  onChanged: _onIdChanged,
                                  decoration:
                                      _inputDecoration(
                                        hint: 'YYMMDDSSSSCAZ',
                                        icon: Icons.badge_outlined,
                                      ).copyWith(
                                        counterText: '',
                                        errorText: _idError,
                                        suffixIcon:
                                            isValidSouthAfricanId(
                                              _idController.text.trim(),
                                            )
                                            ? const Icon(
                                                Icons.check_circle_outline,
                                                color: AppColors.accent,
                                              )
                                            : null,
                                      ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'ID number is required';
                                    }
                                    if (value.length != 13) {
                                      return 'ID number must be 13 digits';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 13,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Gender is determined by digits 7-10 of your SA ID',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white38,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('Phone Number'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: '+27 71 000 0000',
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: _LoginButton(
                                    isLoading: _isLoading,
                                    onPressed: _isLoading ? null : _handleLogin,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.emergency_outlined,
                                      size: 16,
                                      color: AppColors.critical,
                                    ),
                                    label: Text(
                                      'Emergency? Call 10111',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.critical,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white.withValues(alpha: 0.86),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: 0.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.critical, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.critical, width: 1.4),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF14B8A6).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF5EEAD4),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This platform verifies access with your South African ID number.',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF14B8A6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_open_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Enter Safe Hub',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
