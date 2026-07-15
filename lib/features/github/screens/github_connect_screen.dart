import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class GitHubConnectScreen extends ConsumerStatefulWidget {
  const GitHubConnectScreen({super.key});

  @override
  ConsumerState<GitHubConnectScreen> createState() =>
      _GitHubConnectScreenState();
}

class _GitHubConnectScreenState extends ConsumerState<GitHubConnectScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).refreshGitHubAccount();
      ref.read(repositoryProvider.notifier).fetchRepositories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final repos = ref.watch(repositoryProvider);
    final user = auth.user;
    final connected = user?.githubConnected ?? false;

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const PageHeader(
          title: 'Kết nối GitHub',
          subtitle: 'Kết nối OAuth để đồng bộ repository, packages và commits.',
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: auth.error!, isError: true)
        ],
        if (repos.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: repos.error!, isWarning: true)
        ],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: connected
                          ? (context.isDarkMode
                              ? AppColors.emerald.withValues(alpha: 0.2)
                              : const Color(0xFFD1FAE5))
                          : (context.isDarkMode
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : const Color(0xFFE0E7FF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: connected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.emerald)
                        : const AppSvgIcon(
                            asset: AppAssets.githubIcon,
                            size: 24,
                            color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            Text('GitHub OAuth',
                                style: context.appHeadingStyle
                                    .copyWith(fontSize: 18)),
                            AppBadge(
                              label: connected ? 'Đã kết nối' : 'Chưa kết nối',
                              variant: connected
                                  ? AppBadgeVariant.success
                                  : AppBadgeVariant.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connected
                              ? 'Đang kết nối với @${user?.githubUsername ?? 'GitHub'}'
                              : 'Đăng nhập GitHub để cấp quyền đọc repository.',
                          style: context.appCaptionStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Làm mới',
                      outlined: true,
                      loading: _refreshing,
                      onPressed: () async {
                        setState(() => _refreshing = true);
                        await ref
                            .read(authProvider.notifier)
                            .refreshGitHubAccount();
                        setState(() => _refreshing = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: connected
                        ? PrimaryButton(
                            label: 'Ngắt kết nối',
                            outlined: true,
                            loading: auth.isLoading,
                            onPressed: () => ref
                                .read(authProvider.notifier)
                                .disconnectGitHub(),
                          )
                        : PrimaryButton(
                            label: 'Kết nối GitHub',
                            loading: auth.isLoading,
                            onPressed: () =>
                                ref.read(authProvider.notifier).connectGitHub(),
                          ),
                  ),
                ],
              ),
              if (connected) ...[
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Kết nối tài khoản GitHub khác',
                  outlined: true,
                  expand: true,
                  onPressed: auth.isLoading
                      ? null
                      : () =>
                          ref.read(authProvider.notifier).disconnectGitHub(),
                ),
              ],
            ],
          ),
        ),
        if (!connected && auth.showGitHubReconnectActions) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Đã ngắt liên kết trong ứng dụng. GitHub.com có thể vẫn đang đăng nhập tài khoản cũ.',
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Connect lại GitHub',
                  onPressed: auth.isLoading
                      ? null
                      : () => ref
                          .read(authProvider.notifier)
                          .connectGitHub(forceAccountSelection: true),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Đăng xuất GitHub.com để dùng tài khoản khác',
                  outlined: true,
                  onPressed: () => launchUrl(
                    Uri.parse('https://github.com/logout'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sau khi đăng xuất GitHub.com xong, quay lại app và bấm Connect lại GitHub.',
                  style: context.appCaptionStyle,
                ),
              ],
            ),
          ),
        ],
        if (connected) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Repositories đã cache: ${repos.repositories.length}',
                    style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Tải cache',
                  outlined: true,
                  expand: true,
                  loading: repos.isLoading,
                  onPressed: () =>
                      ref.read(repositoryProvider.notifier).fetchRepositories(),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Đồng bộ repositories',
                  expand: true,
                  loading: repos.isLoading,
                  onPressed: () => ref
                      .read(repositoryProvider.notifier)
                      .fetchRepositories(sync: true),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Mở repositories',
                  outlined: true,
                  expand: true,
                  onPressed: () => context.go('/repositories'),
                ),
                const SizedBox(height: 12),
                ...repos.repositories.take(5).map(
                      (r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.fullName),
                        trailing: AppBadge(label: r.language),
                        onTap: () => context.push('/repositories/${r.id}'),
                      ),
                    ),
              ],
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: BannerMessage(
              message:
                  'Cần kết nối GitHub trước khi đồng bộ repository và chạy phân tích.',
              isWarning: true,
            ),
          ),
      ],
    );
  }
}
