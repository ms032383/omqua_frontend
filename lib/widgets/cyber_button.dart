import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class CyberButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final bool isSecondary;

  const CyberButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.trailingIcon,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSecondary = widget.isSecondary;

    final baseBgColor = isSecondary ? Colors.transparent : CyberTheme.cardBg;
    final hoverBgColor = isSecondary 
        ? CyberTheme.accent.withOpacity(0.08) 
        : CyberTheme.accent.withOpacity(0.12);

    final baseBorderColor = isSecondary ? CyberTheme.borderMuted : CyberTheme.borderBright;
    final hoverBorderColor = CyberTheme.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? hoverBgColor : baseBgColor,
            borderRadius: CyberTheme.softBorderRadius,
            border: Border.all(
              color: _isHovered ? hoverBorderColor : baseBorderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _isHovered ? CyberTheme.textWhite : CyberTheme.textGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  widget.trailingIcon,
                  color: _isHovered ? CyberTheme.textWhite : CyberTheme.textGray,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
