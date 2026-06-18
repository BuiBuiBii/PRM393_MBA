import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalLoadingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void show() => state++;

  void hide() {
    if (state > 0) state--;
  }

  Future<T> run<T>(Future<T> Function() action) async {
    show();
    try {
      return await action();
    } finally {
      hide();
    }
  }
}

final globalLoadingProvider = NotifierProvider<GlobalLoadingNotifier, int>(GlobalLoadingNotifier.new);

extension GlobalLoadingRef on WidgetRef {
  GlobalLoadingNotifier get globalLoading => read(globalLoadingProvider.notifier);
}

class GlobalLoadingOverlay extends ConsumerWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(globalLoadingProvider);
    if (count <= 0) return const SizedBox.shrink();

    return const AbsorbPointer(
      child: ColoredBox(
        color: Color(0x660F172A),
        child: Center(child: GlobalLoadingIndicator()),
      ),
    );
  }
}

class GlobalLoadingIndicator extends StatelessWidget {
  const GlobalLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
