import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final isSuccess = await ref.read(authProvider.notifier).login(username, password);

    setState(() => _isLoading = false);

    if (isSuccess && mounted) {
      // 로그인 성공 시 대시보드로 이동
      context.go('/dashboard');
    } else if (mounted) {
      //401 Unauthorized 등 로그인 실패 시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 또는 비밀번호가 올바르지 않습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '안미룬이',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '아이디',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('로그인', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('아직 회원이 아니신가요? 회원가입하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
