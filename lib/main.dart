import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'widgets/shared_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: GreenFieldApp()));
}

class GreenFieldApp extends ConsumerWidget {
  const GreenFieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Edathara Samskarika Samithi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authStateProvider);
    final appUser    = ref.watch(currentAppUserProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error:   (_, __) => const LoginScreen(),
      data: (firebaseUser) {
        if (firebaseUser == null) return const LoginScreen();

        // Firebase user exists — wait for Firestore profile
        return appUser.when(
          loading: () => const _SplashScreen(),
          error:   (_, __) => const LoginScreen(),
          data: (user) {
            if (user == null) {
              // Signed in but no profile yet — collect name
              return _CompleteProfileScreen(
                uid:   firebaseUser.uid,
                phone: firebaseUser.phoneNumber ?? '',
              );
            }
            return const MainShell();
          },
        );
      },
    );
  }
}

// ── Complete Profile Screen ───────────────────────────────────────────────────
class _CompleteProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  final String phone;
  const _CompleteProfileScreen({required this.uid, required this.phone});

  @override
  ConsumerState<_CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<_CompleteProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showError(context, 'Please enter your name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).createPhoneUser(
        uid:   widget.uid,
        name:  name,
        phone: widget.phone,
      );
      // currentAppUserProvider will emit the new doc → _AuthGate → MainShell
    } catch (e) {
      if (mounted) {
        showError(context, 'Could not save profile. Please try again.');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top sign-out button ─────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: TextButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout,
                        size: 16, color: AppColors.error),
                    label: const Text('Sign out',
                        style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        Image.asset('assets/logo.png', width: 80, height: 80),
                        const SizedBox(height: 16),
                        const Text(
                          'One last step 👋',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tell us your name to complete sign-up',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14),
                        ),
                        const SizedBox(height: 32),

                        // ── Card ──────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Phone pill
                              if (widget.phone.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.mist,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 18, color: AppColors.slate),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Signed in as',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.slate)),
                                        Text(widget.phone,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink)),
                                      ],
                                    ),
                                  ]),
                                ),

                              TextFormField(
                                controller: _nameCtrl,
                                autofocus: true,
                                textCapitalization:
                                    TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                onFieldSubmitted: (_) => _save(),
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: 'Continue',
                                isLoading: _isLoading,
                                fullWidth: true,
                                icon: Icons.arrow_forward_outlined,
                                onPressed: _save,
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ── Splash ────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 90, height: 90),
            const SizedBox(height: 16),
            const Text(
              'Edathara\nSamskarika Samithi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
                color: AppColors.mint, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
