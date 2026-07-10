import 'package:flutter/material.dart';

/// Bọc ListView / CustomScrollView — hiện mũi tên khi còn nội dung cuộn được.
class ScrollListHints extends StatefulWidget {
  const ScrollListHints({
    super.key,
    required this.child,
    this.controller,
    this.showTopHint = true,
    this.showBottomHint = true,
    this.minExtentToShow = 48,
  });

  final Widget child;
  final ScrollController? controller;
  final bool showTopHint;
  final bool showBottomHint;
  final double minExtentToShow;

  @override
  State<ScrollListHints> createState() => _ScrollListHintsState();
}

class _ScrollListHintsState extends State<ScrollListHints> {
  ScrollController? _owned;
  var _canScrollUp = false;
  var _canScrollDown = false;

  ScrollController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = ScrollController();
    }
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(ScrollListHints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      _owned?.removeListener(_onScroll);
      if (widget.controller == null) {
        _owned ??= ScrollController();
        _owned!.addListener(_onScroll);
      } else {
        _owned?.dispose();
        _owned = null;
        widget.controller!.addListener(_onScroll);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _owned?.dispose();
    super.dispose();
  }

  void _onScroll([ScrollMetrics? metrics]) {
    final pos = metrics ?? (_controller.hasClients ? _controller.position : null);
    if (pos == null) return;
    final up = pos.pixels > widget.minExtentToShow;
    final down = pos.pixels < pos.maxScrollExtent - widget.minExtentToShow;
    if (up != _canScrollUp || down != _canScrollDown) {
      setState(() {
        _canScrollUp = up;
        _canScrollDown = down;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _onScroll(notification.metrics);
            return false;
          },
          child: widget.child,
        ),
        if (widget.showTopHint && _canScrollUp)
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(child: _HintButton(
              icon: Icons.keyboard_arrow_up_rounded,
              color: scheme.primary,
              onTap: () => _scrollBy(-220),
            )),
          ),
        if (widget.showBottomHint && _canScrollDown)
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(child: _HintButton(
              icon: Icons.keyboard_arrow_down_rounded,
              color: scheme.primary,
              onTap: () => _scrollBy(220),
            )),
          ),
      ],
    );
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
