import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Big, tactile, rounded button with a hard "pressed" feel.
class ChunkyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final bool expand;

  const ChunkyButton({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.lime,
    this.onTap,
    this.loading = false,
    this.expand = true,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.onAccent(widget.color);
    final disabled = widget.onTap == null || widget.loading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: disabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: disabled ? widget.color.withOpacity(0.35) : widget.color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _down || disabled
              ? []
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3, color: fg),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 22),
                const SizedBox(width: 10),
              ],
              Text(widget.label,
                  style: AppTheme.display(17, color: fg, weight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}
