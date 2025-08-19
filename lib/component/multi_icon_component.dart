import 'package:flutter/material.dart';

class MultiIconComponent extends StatelessWidget {
  IconData icon;

  IconData smallIcon;

  final double? size;

  final Color? color;

  MultiIconComponent(
      {super.key,
      required this.icon,
      required this.smallIcon,
      this.size,
      this.color});

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size ?? kDefaultFontSize;
    Color? iconColor = color ?? iconTheme.color!;

    return Container(
      width: iconSize + 2,
      child: Stack(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
          Positioned(
            right: 0,
            child: Icon(
              smallIcon,
              size: iconSize * 0.5,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
