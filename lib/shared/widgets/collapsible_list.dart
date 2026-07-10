import 'package:flutter/material.dart';

import 'app_widgets.dart';

/// Nút bật/tắt hiển thị thêm mục trong danh sách.
class ShowMoreListToggle extends StatelessWidget {
  const ShowMoreListToggle({
    super.key,
    required this.expanded,
    required this.hiddenCount,
    required this.onToggle,
    this.expandLabel,
    this.collapseLabel = 'Thu gọn',
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onToggle;
  final String? expandLabel;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    if (hiddenCount <= 0) return const SizedBox.shrink();

    final label = expanded
        ? collapseLabel
        : (expandLabel ?? 'Hiển thị thêm ($hiddenCount)');

    return Center(
      child: TextButton.icon(
        onPressed: onToggle,
        icon: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          size: 20,
          color: AppColors.primary,
        ),
        label: Text(label),
      ),
    );
  }
}

/// Danh sách dọc: mặc định chỉ hiện [initialVisibleCount] mục, bấm để xem thêm.
class CollapsibleItemList<T> extends StatefulWidget {
  const CollapsibleItemList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialVisibleCount = 5,
    this.itemSpacing = 12,
    this.expandLabelBuilder,
    this.collapseLabel = 'Thu gọn',
    this.resetKey,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int initialVisibleCount;
  final double itemSpacing;
  final String Function(int hiddenCount)? expandLabelBuilder;
  final String collapseLabel;

  /// Đổi key (vd. bộ lọc/tìm kiếm) để tự thu gọn lại danh sách.
  final Object? resetKey;

  @override
  State<CollapsibleItemList<T>> createState() => _CollapsibleItemListState<T>();
}

class _CollapsibleItemListState<T> extends State<CollapsibleItemList<T>> {
  bool _expanded = false;
  Object? _lastResetKey;

  @override
  void didUpdateWidget(CollapsibleItemList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final resetChanged = widget.resetKey != null && widget.resetKey != _lastResetKey;
    final lengthChanged = oldWidget.items.length != widget.items.length;
    if (resetChanged || lengthChanged) {
      _expanded = false;
      _lastResetKey = widget.resetKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    _lastResetKey ??= widget.resetKey;

    final total = widget.items.length;
    final limit = widget.initialVisibleCount;
    final canCollapse = total > limit;
    final visibleItems = (!_expanded && canCollapse) ? widget.items.take(limit).toList() : widget.items;

    return Column(
      children: [
        for (var i = 0; i < visibleItems.length; i++) ...[
          if (i > 0) SizedBox(height: widget.itemSpacing),
          widget.itemBuilder(context, visibleItems[i]),
        ],
        if (canCollapse) ...[
          SizedBox(height: widget.itemSpacing),
          ShowMoreListToggle(
            expanded: _expanded,
            hiddenCount: total - limit,
            expandLabel: widget.expandLabelBuilder?.call(total - limit),
            collapseLabel: widget.collapseLabel,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ],
    );
  }
}
