import 'package:flutter/material.dart';

/// 消息类型
enum MessageType {
  success,
  error,
  warning,
  info,
}

/// 消息位置
enum MessagePosition {
  top,
  bottom,
}

/// 消息提示组件
class MessageToast extends StatefulWidget {
  final String message;
  final MessageType type;
  final MessagePosition position;
  final Duration duration;
  final VoidCallback? onDismiss;

  const MessageToast({
    super.key,
    required this.message,
    this.type = MessageType.info,
    this.position = MessagePosition.top,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<MessageToast> createState() => _MessageToastState();
}

class _MessageToastState extends State<MessageToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final offset = widget.position == MessagePosition.top
        ? const Offset(0, -1)
        : const Offset(0, 1);

    _slideAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 自动消失
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFFE8F5E9);
      case MessageType.error:
        return const Color(0xFFFFEBEE);
      case MessageType.warning:
        return const Color(0xFFFFF8E1);
      case MessageType.info:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF2E7D32);
      case MessageType.error:
        return const Color(0xFFC62828);
      case MessageType.warning:
        return const Color(0xFFEF6C00);
      case MessageType.info:
        return const Color(0xFF1565C0);
    }
  }

  Color get _iconColor {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF4CAF50);
      case MessageType.error:
        return const Color(0xFFEF5350);
      case MessageType.warning:
        return const Color(0xFFFF9800);
      case MessageType.info:
        return const Color(0xFF2196F3);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_rounded;
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      case MessageType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: _iconColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _icon,
                        color: _iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.close_rounded,
                          color: _textColor.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息提示工具类
class MessageService {
  static final List<_MessageEntry> _entries = [];

  /// 显示成功消息
  static void success(
    BuildContext context,
    String message, {
    MessagePosition position = MessagePosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, MessageType.success, position, duration);
  }

  /// 显示错误消息
  static void error(
    BuildContext context,
    String message, {
    MessagePosition position = MessagePosition.top,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(context, message, MessageType.error, position, duration);
  }

  /// 显示警告消息
  static void warning(
    BuildContext context,
    String message, {
    MessagePosition position = MessagePosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, MessageType.warning, position, duration);
  }

  /// 显示信息消息
  static void info(
    BuildContext context,
    String message, {
    MessagePosition position = MessagePosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, MessageType.info, position, duration);
  }

  static void _show(
    BuildContext context,
    String message,
    MessageType type,
    MessagePosition position,
    Duration duration,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _PositionedToast(
        position: position,
        child: MessageToast(
          message: message,
          type: type,
          position: position,
          duration: duration,
          onDismiss: () {
            _removeEntry(entry);
          },
        ),
      ),
    );

    _entries.add(_MessageEntry(entry, position));
    _rebuildAll();
    overlay.insert(entry);
  }

  static void _removeEntry(OverlayEntry entry) {
    final index = _entries.indexWhere((e) => e.entry == entry);
    if (index != -1) {
      _entries[index].entry.remove();
      _entries.removeAt(index);
      _rebuildAll();
    }
  }

  static void _rebuildAll() {
    for (var i = 0; i < _entries.length; i++) {
      _entries[i].entry.markNeedsBuild();
    }
  }
}

class _MessageEntry {
  final OverlayEntry entry;
  final MessagePosition position;

  _MessageEntry(this.entry, this.position);
}

/// 定位容器，支持多条消息堆叠
class _PositionedToast extends StatelessWidget {
  final MessagePosition position;
  final Widget child;

  const _PositionedToast({
    required this.position,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final samePositionCount = MessageService._entries
        .where((e) => e.position == position)
        .length;

    final baseOffset = position == MessagePosition.top ? 60.0 : 0.0;
    final stackOffset = (samePositionCount - 1) * 72.0;

    return Positioned(
      top: position == MessagePosition.top ? baseOffset + stackOffset : null,
      bottom: position == MessagePosition.bottom ? baseOffset + stackOffset : null,
      left: 0,
      right: 0,
      child: child,
    );
  }
}
