import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../feature_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/roadmap_generate_params.dart';

/// Tạo roadmap từ params Dev2Vec và điều hướng tới chi tiết.
Future<void> generateAndOpenRoadmap(
  BuildContext context,
  WidgetRef ref,
  RoadmapGenerateParams params,
) async {
  final notifier = ref.read(roadmapProvider.notifier);
  notifier.setTargetRole(params.targetRole);
  try {
    if (ref.read(roadmapProvider).statusFilter != 'active') {
      await notifier.setStatusFilter('active');
    }
    final roadmap = await notifier.generateAI(params: params);
    if (!context.mounted || roadmap == null) return;
    AppSnackbar.show(
      context,
      message: 'Đã tạo roadmap cho ${params.targetRole}',
      variant: AppSnackVariant.success,
    );
    context.push(
        '/roadmaps/${roadmap.slug.isNotEmpty ? roadmap.slug : roadmap.id}');
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.show(
        context,
        message: ref.read(roadmapProvider).error ?? 'Không thể tạo roadmap',
        variant: AppSnackVariant.error,
      );
    }
  }
}
