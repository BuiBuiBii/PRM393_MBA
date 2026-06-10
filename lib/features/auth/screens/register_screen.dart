import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/auth_layout.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _acceptedTerms = false;
  var _oauthNotice = '';
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showLegalNotice(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          '$title sẽ được cập nhật trên website chính thức. '
          'Hiện tại bạn chỉ cần tick đồng ý để tiếp tục đăng ký.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _localError = null);

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _localError = 'Mật khẩu xác nhận không khớp');
      return;
    }
    if (!_acceptedTerms) {
      setState(() => _localError = 'Vui lòng đồng ý với điều khoản sử dụng');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      if (mounted) context.go('/dashboard');
    } catch (_) {}
  }

  Future<void> _submitGoogle() async {
    if (!AppConfig.isGoogleLoginConfigured) {
      setState(() => _oauthNotice = 'Chưa cấu hình GOOGLE_CLIENT_ID.');
      return;
    }
    setState(() => _oauthNotice = '');
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (mounted) context.go('/dashboard');
    } catch (_) {}
  }

  Future<void> _submitGithub() async {
    if (!AppConfig.isGithubLoginConfigured) {
      setState(() {
        _oauthNotice =
            'Chưa cấu hình GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET cho đăng nhập GitHub.';
      });
      return;
    }
    setState(() => _oauthNotice = '');
    try {
      await ref.read(authProvider.notifier).loginWithGithub();
      if (mounted) context.go('/dashboard');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final error = _localError ?? auth.error;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppBrandLogo(size: 48, withBackground: true)),
          const SizedBox(height: 16),
          const Center(child: AppBadge(label: 'Tạo workspace', variant: AppBadgeVariant.info)),
          const SizedBox(height: 8),
          Text(
            'Tạo tài khoản',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu phân tích repository với GitAnalyzer AI',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          AuthCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (error != null) ...[
                      BannerMessage(message: error, isError: true),
                      const SizedBox(height: 16),
                    ],
                    LabeledInput(
                      label: 'Họ và tên',
                      controller: _nameController,
                      icon: Icons.person_outline,
                      placeholder: 'Nguyễn Minh',
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 16),
                    LabeledInput(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      placeholder: 'you@example.com',
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Vui lòng nhập email' : null,
                    ),
                    const SizedBox(height: 16),
                    LabeledInput(
                      label: 'Mật khẩu',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      placeholder: 'Tạo mật khẩu',
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mật khẩu tối thiểu 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    LabeledInput(
                      label: 'Xác nhận mật khẩu',
                      controller: _confirmPasswordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      placeholder: 'Nhập lại mật khẩu',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 14, color: AppColors.slate600),
                              children: [
                                const TextSpan(text: 'Tôi đồng ý với '),
                                TextSpan(
                                  text: 'Điều khoản sử dụng',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showLegalNotice(context, 'Điều khoản sử dụng'),
                                ),
                                const TextSpan(text: ' và '),
                                TextSpan(
                                  text: 'Chính sách bảo mật',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showLegalNotice(context, 'Chính sách bảo mật'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Tạo tài khoản',
                      expand: true,
                      loading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 24),
                    const AuthDivider(label: 'Hoặc đăng ký với'),
                    if (_oauthNotice.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      BannerMessage(message: _oauthNotice, isWarning: true),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'GitHub',
                            outlined: true,
                            loading: auth.isLoading,
                            leading: const AppSvgIcon(asset: AppAssets.githubIcon, size: 18),
                            onPressed: auth.isLoading ? null : _submitGithub,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Google',
                            outlined: true,
                            loading: auth.isLoading,
                            leading: const AppSvgIcon(asset: AppAssets.googleIcon, size: 18),
                            onPressed: auth.isLoading ? null : _submitGoogle,
                          ),
                        ),
                      ],
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
              const Text('Đã có tài khoản? ', style: TextStyle(color: AppColors.slate500, fontSize: 14)),
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w500)),
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
