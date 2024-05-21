import 'package:flutter/material.dart';

class EventBitcionIconComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 8,
          color: Colors.amber[600]!.withOpacity(0.5),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(54),
      ),
      child: Icon(
        Icons.currency_bitcoin,
        color: Colors.amber[600]!.withOpacity(0.5),
        size: 100,
      ),
    );
  }

  static Widget wrapper(Widget child) {
    return Stack(
      children: [
        child,
        Positioned(
          top: -35,
          right: -10,
          child: EventBitcionIconComponent(),
        ),
      ],
    );
  }
}
