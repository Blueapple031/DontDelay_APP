import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import 'auth_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Timer? _debounceTimer;
  bool _showConfirmError = false;

  String? get _confirmError {
    if (!_showConfirmError) return null;
    if (_passwordConfirmController.text.isEmpty) return null;
    if (_passwordController.text != _passwordConfirmController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _passwordConfirmController.addListener(_onConfirmChanged);
  }

  void _onPasswordChanged() {
    if (_passwordConfirmController.text.isNotEmpty) {
      _startDebounce();
    }
  }

  void _onConfirmChanged() {
    _startDebounce();
  }

  void _startDebounce() {
    if (_showConfirmError) setState(() => _showConfirmError = false);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showConfirmError = true);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _departmentController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _handleSignUp() async {
    final lastName = _lastNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final department = _departmentController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();
    final email = _emailController.text.trim();

    if (lastName.isEmpty ||
        firstName.isEmpty ||
        department.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty ||
        email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    if (password != passwordConfirm) {
      _debounceTimer?.cancel();
      setState(() => _showConfirmError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final realName = '$lastName$firstName';

    final errorMessage = await ref.read(authProvider.notifier).signUp(
          username: username,
          password: password,
          realName: realName,
          email: email,
          department: department,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              Color.alphaBlend(cs.primaryContainer.withOpacity(0.25), cs.surface),
              cs.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.07),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: cs.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '회원가입',
                                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontSize: 22,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                '새 계정을 만들어보세요',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(color: cs.outlineVariant, height: 40),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AuthTextField(
                              controller: _lastNameController,
                              label: '성',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: AuthTextField(
                              controller: _firstNameController,
                              label: '이름',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      AuthTextField(
                        controller: _departmentController,
                        label: '학과',
                        icon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      AuthTextField(
                        controller: _usernameController,
                        label: '아이디',
                        icon: Icons.alternate_email_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      AuthTextField(
                        controller: _passwordController,
                        label: '비밀번호',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        onToggleObscure: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      AuthTextField(
                        controller: _passwordConfirmController,
                        label: '비밀번호 확인',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        textInputAction: TextInputAction.next,
                        errorText: _confirmError,
                      ),
                      const SizedBox(height: 14),

                      AuthTextField(
                        controller: _emailController,
                        label: '이메일',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _handleSignUp(),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : Text(
                                  '가입하기',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontSize: 16,
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
  }
}
