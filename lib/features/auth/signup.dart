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

  /// 디바운스 타이머 — 마지막 입력으로부터 600 ms 후 오류 표시
  Timer? _debounceTimer;

  /// true 일 때만 오류 문구를 렌더링
  bool _showConfirmError = false;

  /// 디바운스가 완료된 시점에 비밀번호 일치 여부를 반환
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

  /// 원본 비밀번호가 바뀌었을 때: 확인 필드에 내용이 있으면 디바운스 재시작
  void _onPasswordChanged() {
    if (_passwordConfirmController.text.isNotEmpty) {
      _startDebounce();
    }
  }

  /// 확인 필드 입력마다 디바운스 재시작
  void _onConfirmChanged() {
    _startDebounce();
  }

  void _startDebounce() {
    // 타이핑 중엔 오류 즉시 숨김
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

    // 모든 항목 입력 확인
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

    // 비밀번호 일치 확인
    if (password != passwordConfirm) {
      _debounceTimer?.cancel();
      setState(() => _showConfirmError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    // 이메일 형식 확인
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 성 + 이름 조합 (한국식: 공백 없이)
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
                      // ── 헤더 ──────────────────────────────────────
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

                      // ── 행 1: 성 + 이름 ───────────────────────────
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

                      // ── 행 2: 학과 ─────────────────────────────────
                      AuthTextField(
                        controller: _departmentController,
                        label: '학과',
                        icon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      // ── 행 3: 아이디 ────────────────────────────────
                      AuthTextField(
                        controller: _usernameController,
                        label: '아이디',
                        icon: Icons.alternate_email_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      // ── 행 4: 비밀번호 ──────────────────────────────
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

                      // ── 행 5: 비밀번호 확인 ─────────────────────────
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

                      // ── 행 6: 이메일 ────────────────────────────────
                      AuthTextField(
                        controller: _emailController,
                        label: '이메일',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _handleSignUp(),
                      ),
                      const SizedBox(height: 28),

                      // ── 가입하기 버튼 ───────────────────────────────
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
