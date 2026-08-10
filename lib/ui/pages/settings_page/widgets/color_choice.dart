import 'package:flutter/material.dart';

final class ColorChoice extends StatelessWidget {
  const ColorChoice({
    required this.color,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => InkResponse(
    mouseCursor: WidgetStateMouseCursor.clickable,
    onTap: onSelected,
    radius: 24,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    ),
  );
}
