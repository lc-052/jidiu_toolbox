// lib/shared/widgets/grid_cell.dart
import 'package:flutter/material.dart';

/// A single cell rendered inside a grid-based layout.
class GridCell extends StatelessWidget {
  final Color backgroundColor;
  final String? label;
  final double borderRadius;

  const GridCell({
    super.key,
    this.backgroundColor = Colors.transparent,
    this.label,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: label != null
          ? Text(
              label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : null,
    );
  }
}
