import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'error_state.dart';
import 'global_loading.dart';
import 'skeleton_loading.dart';

class AsyncListBody extends StatelessWidget {
  const AsyncListBody({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.child,
    this.error,
    this.onRetry,
    this.emptyTitle = 'Không có dữ liệu',
    this.emptySubtitle,
    this.emptyAction,
    this.skeletonCount = 4,
    this.useSkeleton = true,
    this.useCards = false,
    this.padding,
  });

  final bool isLoading;
  final bool isEmpty;
  final Widget child;
  final String? error;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;
  final int skeletonCount;
  final bool useSkeleton;
  final bool useCards;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (isLoading && isEmpty) {
      if (useSkeleton) {
        return SkeletonList(itemCount: skeletonCount, useCards: useCards, padding: padding);
      }
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: GlobalLoadingIndicator()),
      );
    }

    if (!isLoading && isEmpty && error != null) {
      return ErrorState(
        message: error!,
        onRetry: onRetry,
      );
    }

    if (!isLoading && isEmpty) {
      return EmptyState(title: emptyTitle, subtitle: emptySubtitle, action: emptyAction);
    }

    return child;
  }
}

class AsyncPageBody extends StatelessWidget {
  const AsyncPageBody({
    super.key,
    required this.isLoading,
    required this.hasData,
    required this.child,
    this.error,
    this.onRetry,
    this.loadingMessage,
    this.useSkeleton = true,
  });

  final bool isLoading;
  final bool hasData;
  final Widget child;
  final String? error;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final bool useSkeleton;

  @override
  Widget build(BuildContext context) {
    if (isLoading && !hasData) {
      if (useSkeleton) {
        return ListView(
          padding: appScreenPadding(context),
          children: const [
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
          ],
        );
      }
      return Center(child: GlobalLoadingIndicator(message: loadingMessage));
    }

    if (!isLoading && !hasData && error != null) {
      return ErrorState(message: error!, onRetry: onRetry);
    }

    return child;
  }
}
