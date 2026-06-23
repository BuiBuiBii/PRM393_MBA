import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../app_providers.dart';

class SnapshotSelectRepoScreen extends ConsumerStatefulWidget {
  const SnapshotSelectRepoScreen({super.key});

  @override
  ConsumerState<SnapshotSelectRepoScreen> createState() => _SnapshotSelectRepoScreenState();
}

class _SnapshotSelectRepoScreenState extends ConsumerState<SnapshotSelectRepoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(repositoryProvider.notifier).fetchRepositories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final repos = state.repositories;
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text('Chọn Repository'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
      ),
      body: isLoading && repos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : repos.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: repos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final repo = repos[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.slate200),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push('/repositories/${repo.id}/snapshots');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.folder_outlined, color: AppColors.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      repo.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (repo.description != null && repo.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        repo.description!,
                                        style: const TextStyle(color: AppColors.slate500, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.slate400),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off_outlined, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          const Text(
            'Chưa có repository nào.\nHãy đồng bộ repository của bạn trước.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Đến trang Repositories',
            onPressed: () => context.go('/repositories'),
          ),
        ],
      ),
    );
  }
}
