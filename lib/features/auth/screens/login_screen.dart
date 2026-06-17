import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/auth_navigation.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/auth_layout.dart';
import '../../../shared/widgets/social_login_panel.dart';
import '../../auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _rememberMe = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.demoMode) {
      _emailController.text = AppConfig.demoEmail;
      _passwordController.text = AppConfig.demoPassword;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) context.go(getDefaultAuthenticatedPath(ref.read(authProvider).user));
    } catch (_) {}
  }

  Future<void> _demoLogin() async {
    _emailController.text = AppConfig.demoEmail;
    _passwordController.text = AppConfig.demoPassword;
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppBrandLogo(size: 48, withBackground: true)),
          const SizedBox(height: 16),
          const Center(child: AppBadge(label: 'Chào mừng trở lại', variant: AppBadgeVariant.info)),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập GitAnalyzer',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tiếp tục vào workspace phân tích repository của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          if (AppConfig.demoMode)
            const BannerMessage(
              message: 'Chế độ demo: dùng demo@gitanalyzer.vn / demo123 hoặc bấm nút bên dưới.',
            ),
          if (AppConfig.demoMode) const SizedBox(height: 12),
          AuthCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (auth.error != null) ...[
                      BannerMessage(message: auth.error!, isError: true),
                      const SizedBox(height: 16),
                    ],
                    LabeledInput(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      placeholder: 'you@example.com',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    LabeledInput(
                      label: 'Mật khẩu',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      placeholder: 'Nhập mật khẩu',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 14, color: AppColors.slate600)),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng quên mật khẩu đang được phát triển. Vui lòng liên hệ quản trị viên.'),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Đăng nhập',
                      expand: true,
                      loading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    if (AppConfig.demoMode) ...[
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Vào demo ngay (không cần BE)',
                        expand: true,
                        outlined: true,
                        loading: auth.isLoading,
                        onPressed: _demoLogin,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SocialLoginPanel(
                      dividerLabel: 'Hoặc tiếp tục với',
                      onSuccess: () {
                        if (mounted) context.go(getDefaultAuthenticatedPath(ref.read(authProvider).user));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.slate500, fontSize: 14)),
              TextButton(
                onPressed: () => context.go('/register'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (MediaQuery.sizeOf(context).height > 720) ...[
            const SizedBox(height: 24),
            const AuthShowcasePanel(),
          ],
        ],
      ),
    );
  }
}
