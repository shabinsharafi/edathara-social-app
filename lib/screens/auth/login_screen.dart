import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int  _step    = 0;     // 0 = phone, 1 = otp, 2 = name (first-time login only)
  bool _isLogin = true;
  bool _isLoading = false;

  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  String? _verificationId;
  String? _pendingUid;   // uid held while waiting for name in step 2

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final p = _phoneCtrl.text.trim();
    return p.startsWith('+') ? p : '+91$p';
  }

  // ── Step 1: Send OTP ────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      showError(context, 'Enter your mobile number');
      return;
    }
    if (phone.length < 10) {
      showError(context, 'Enter a valid 10-digit number');
      return;
    }
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      showError(context, 'Enter your full name');
      return;
    }

    setState(() => _isLoading = true);

    await ref.read(authServiceProvider).sendOtp(
      phone: _fullPhone,
      codeSent: (vId, _) {
        _verificationId = vId;
        if (mounted) setState(() { _step = 1; _isLoading = false; });
      },
      failed: (err) {
        if (mounted) {
          showError(context, err);
          setState(() => _isLoading = false);
        }
      },
    );
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      showError(context, 'Enter the 6-digit OTP');
      return;
    }
    if (_verificationId == null) return;

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      final cred = await auth.verifyOtp(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final uid = cred.user!.uid;

      // Create profile if this is a new user
      final existing = await auth.getUserDoc(uid);
      if (existing == null) {
        if (_isLogin) {
          // First-time login — no name collected yet, ask for it
          if (mounted) setState(() { _pendingUid = uid; _step = 2; _isLoading = false; });
          return;
        }
        await auth.createPhoneUser(
            uid: uid, name: _nameCtrl.text.trim(), phone: _fullPhone);
      }
      // Auth state change handled by authStateProvider → navigator
    } on Exception catch (e) {
      if (mounted) {
        showError(context, e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Step 3: Save name for first-time login users ────────────────────────────
  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showError(context, 'Please enter your name');
      return;
    }
    if (_pendingUid == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).createPhoneUser(
          uid: _pendingUid!, name: name, phone: _fullPhone);
      // Auth state provider picks up the signed-in user and navigates
    } on Exception catch (e) {
      if (mounted) {
        showError(context, e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.forest, AppColors.green, Color(0xFF52B78833)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.6, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/logo.png', width: 100, height: 100),
                ).animate().fadeIn(duration: 600.ms).scale(),
                const SizedBox(height: 16),
                Text(
                  'Edathara Samskarika Samithi',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                Text(
                  'Your sports & arts hub',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 36),

                // Animated card swap between steps
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0.05, 0), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: _step == 0 ? _PhoneCard(
                    key: const ValueKey('phone'),
                    isLogin: _isLogin,
                    isLoading: _isLoading,
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    onSend: _sendOtp,
                    onToggle: () => setState(() => _isLogin = !_isLogin),
                  ) : _step == 1 ? _OtpCard(
                    key: const ValueKey('otp'),
                    fullPhone: _fullPhone,
                    isLoading: _isLoading,
                    otpCtrl: _otpCtrl,
                    onVerify: _verifyOtp,
                    onResend: _sendOtp,
                    onBack: () => setState(() {
                      _step = 0;
                      _otpCtrl.clear();
                    }),
                  ) : _ProfileCard(
                    key: const ValueKey('profile'),
                    isLoading: _isLoading,
                    nameCtrl: _nameCtrl,
                    onSave: _saveName,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Phone Card ────────────────────────────────────────────────────────────────
class _PhoneCard extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onSend;
  final VoidCallback onToggle;

  const _PhoneCard({
    super.key,
    required this.isLogin,
    required this.isLoading,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.onSend,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLogin ? 'Welcome back 👋' : 'Create account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isLogin
                ? 'Enter your mobile number to sign in'
                : 'Join Edathara Samskarika Samithi today',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          if (!isLogin) ...[
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
          ],

          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone_outlined),
              prefixText: '+91  ',
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            label: 'Send OTP',
            isLoading: isLoading,
            fullWidth: true,
            icon: Icons.send_outlined,
            onPressed: onSend,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? "Don't have an account? " : 'Already have an account? ',
                style: const TextStyle(color: AppColors.slate, fontSize: 13),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  isLogin ? 'Register' : 'Sign In',
                  style: const TextStyle(
                    color: AppColors.mint,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── OTP Card ──────────────────────────────────────────────────────────────────
class _OtpCard extends StatelessWidget {
  final String fullPhone;
  final bool isLoading;
  final TextEditingController otpCtrl;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _OtpCard({
    super.key,
    required this.fullPhone,
    required this.isLoading,
    required this.otpCtrl,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: onBack,
              child: const Icon(Icons.arrow_back_ios_new_outlined,
                  size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: 10),
            Text('Verify OTP',
                style: Theme.of(context).textTheme.headlineMedium),
          ]),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.slate, fontSize: 13),
              children: [
                const TextSpan(text: 'A 6-digit code was sent to '),
                TextSpan(
                  text: fullPhone,
                  style: const TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800,
                letterSpacing: 12, color: AppColors.ink),
            decoration: const InputDecoration(
              hintText: '······',
              hintStyle: TextStyle(
                  letterSpacing: 12, color: AppColors.border, fontSize: 28),
            ),
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Verify & Continue',
            isLoading: isLoading,
            fullWidth: true,
            icon: Icons.check_circle_outline,
            onPressed: onVerify,
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: isLoading ? null : onResend,
              child: const Text('Resend OTP',
                  style: TextStyle(color: AppColors.mint, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card (first-time login — collect name) ────────────────────────────
class _ProfileCard extends StatelessWidget {
  final bool isLoading;
  final TextEditingController nameCtrl;
  final VoidCallback onSave;

  const _ProfileCard({
    super.key,
    required this.isLoading,
    required this.nameCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('One last step 👋',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Tell us your name to complete your profile.',
            style: TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Continue',
            isLoading: isLoading,
            fullWidth: true,
            icon: Icons.arrow_forward_outlined,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
