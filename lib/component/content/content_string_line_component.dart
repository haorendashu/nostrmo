import 'package:flutter/material.dart';

class ContentStringLineComponent extends StatelessWidget {
  String str;

  ContentStringLineComponent({required this.str});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(str),
    );
  }
}
