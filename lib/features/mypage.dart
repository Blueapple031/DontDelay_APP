import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme_provider.dart';
import 'todo/tag_provider.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_provider.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  void _refreshProfile() {
    if (ref.read(authProvider)) {
      ref.read(userProfileProvider.notifier).load();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  // 프로필 사진 변경 로직 (추후 image_picker 등 연동 필요)
  void _changeProfileImage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프로필 사진 변경 기능은 추후 구현됩니다.')));
  }

  // 테마 색상 변경 다이얼로그
  void _showThemeSelectionDialog() {
    final currentTheme =
        ref.watch(themeProvider).value ?? AppThemeType.classicGray;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '테마 색상 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: AppThemeType.values.map((themeType) {
              final isSelected = themeType == currentTheme;
              final List<Color> themeColors = switch (themeType) {
                AppThemeType.classicGray => const [
                  Color(0xFFEBEBEB),
                  Color(0xFF8E8E8E),
                ],
                AppThemeType.limeCoral => const [
                  Color(0xFFC3DC68),
                  Color(0xFF7D8F24),
                ],
              };
              final themeColor = themeColors.last;

              return GestureDetector(
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(themeType);
                  ref.invalidate(tagListProvider);
                  Navigator.pop(context);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: themeType.label,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: themeColors,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // 비밀번호 변경 다이얼로그
  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField('현재 비밀번호'),
            const SizedBox(height: 12),
            _buildDialogTextField('새 비밀번호'),
            const SizedBox(height: 12),
            _buildDialogTextField('새 비밀번호 확인'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // TODO: 비밀번호 변경 서버 로직 연동
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
              );
            },
            child: const Text(
              '변경하기',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 다이얼로그용 텍스트 필드 빌더
  Widget _buildDialogTextField(String hint) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 로그아웃 확인 다이얼로그
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    ref.listen(authProvider, (previous, loggedIn) {
      if (loggedIn && previous != loggedIn) {
        _refreshProfile();
      }
    });

    final profile = ref.watch(userProfileProvider);
    final displayName = profile?.displayName ?? '사용자';
    final email = profile?.email ?? '';
    final department = profile?.department ?? '';
    final username = profile?.username ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 페이지 타이틀
            const Text(
              '마이페이지',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 2. 메인 콘텐츠 (데스크톱 환경에 맞게 가운데 정렬 및 최대 너비 제한)
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // --- [프로필 섹션] ---
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            // 프로필 이미지
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade200,
                                  // backgroundImage: NetworkImage('이미지 URL'), // 실제 이미지 연동 시 주석 해제
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _changeProfileImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (department.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                department,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (username.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@$username',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- [설정 리스트 섹션] ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [

                            _buildSettingMenu(
                              icon: Icons.palette_outlined,
                              title: '테마 색상 설정',
                              subtitle: '앱의 기본 테마 색상을 변경합니다.',
                              onTap: _showThemeSelectionDialog,
                            ),
                            const Divider(height: 1),
                            _buildSettingMenu(
                              icon: Icons.lock_outline,
                              title: '비밀번호 변경',
                              subtitle: '주기적인 변경으로 계정을 안전하게 보호하세요.',
                              onTap: _changePassword,
                            ),
                            const Divider(height: 1),
                            _buildSettingMenu(
                              icon: Icons.logout_rounded,
                              title: '로그아웃',
                              subtitle: '현재 기기에서 로그아웃 합니다.',
                              titleColor: Colors.redAccent,
                              iconColor: Colors.redAccent,
                              onTap: _confirmLogout,
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
    );
  }

  // 설정 메뉴 아이템 위젯
  Widget _buildSettingMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = Colors.black87,
    Color? iconColor,
  }) {
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
